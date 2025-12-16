import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/clickable_link.dart';
import 'package:sonos_dialoger/components/input_box.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/core/payment.dart';

import '../../components/misc.dart';
import '../../components/timespan_dropdowns.dart';
import '../../providers.dart';
import '../../providers/date_ranges.dart';

final locationProvider = FutureProvider.family(
  (ref, String locationId) =>
      FirebaseFirestore.instance.collection("locations").doc(locationId).get(),
);

final locationPaymentsProvider = StreamProvider.family((
  ref,
  String locationId,
) {
  return FirebaseFirestore.instance
      .collection("payments")
      .where(
        Filter.and(
          ref.watch(paymentsDateFilterProvider),
          Filter("location", isEqualTo: locationId),
        ),
      )
      .orderBy("timestamp", descending: true)
      .snapshots();
});

class LocationDetailsPage extends ConsumerWidget {
  final String locationId;

  const LocationDetailsPage({super.key, required this.locationId});

  BarChartGroupData generateGroupData(int millis, List<Payment> payments) {
    final onceTwint = payments
        .where(
          (payment) =>
              payment is OncePayment &&
              payment.paymentMethod == PaymentMethod.twint,
        )
        .fold(0.0, (total, payment) => total + payment.amount);
    final onceSumup = payments
        .where(
          (payment) =>
              payment is OncePayment &&
              payment.paymentMethod == PaymentMethod.sumup,
        )
        .fold(0.0, (total, payment) => total + payment.amount);
    final repeatingWithFirstPaymentTwint = payments
        .where(
          (payment) =>
              payment is RepeatingPayment &&
              payment is RepeatingPaymentWithFirstPayment &&
              payment.paymentMethod == PaymentMethod.twint,
        )
        .fold(0.0, (total, payment) => total + payment.amount);
    final repeatingWithFirstPaymentSumup = payments
        .where(
          (payment) =>
              payment is RepeatingPayment &&
              payment is RepeatingPaymentWithFirstPayment &&
              payment.paymentMethod == PaymentMethod.sumup,
        )
        .fold(0.0, (total, payment) => total + payment.amount);
    final repeatingWithoutFirstPayment = payments
        .where(
          (payment) =>
              payment is RepeatingPayment &&
              payment is RepeatingPaymentWithoutFirstPayment,
        )
        .fold(0.0, (total, payment) => total + payment.amount);
    return BarChartGroupData(
      x: millis,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: onceTwint.toDouble(),
          color: Colors.lightBlue.shade600,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          fromY: onceTwint,
          toY: onceTwint + onceSumup,
          color: Colors.lightBlue.shade200,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          fromY: onceTwint + onceSumup,
          toY: onceTwint + onceSumup + repeatingWithFirstPaymentTwint,
          color: Colors.lightGreen.shade800,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          fromY: onceTwint + onceSumup + repeatingWithFirstPaymentTwint,
          toY:
              onceTwint +
              onceSumup +
              repeatingWithFirstPaymentTwint +
              repeatingWithFirstPaymentSumup,
          color: Colors.lightGreen.shade300,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
        BarChartRodData(
          fromY:
              onceTwint +
              onceSumup +
              repeatingWithFirstPaymentTwint +
              repeatingWithFirstPaymentSumup,
          toY:
              onceTwint +
              onceSumup +
              repeatingWithFirstPaymentTwint +
              repeatingWithFirstPaymentSumup +
              repeatingWithoutFirstPayment,
          color: Colors.amberAccent.shade200,
          width: 15,
          borderRadius: BorderRadius.zero,
        ),
      ],
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    if (value == meta.max) {
      return Container();
    }
    const style = TextStyle(fontSize: 10);
    return SideTitleWidget(
      meta: meta,
      child: Text(meta.formattedValue, style: style),
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final locationDoc = ref.watch(locationProvider(locationId));
    if (locationDoc.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (locationDoc.hasError) {
      print(locationDoc.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    final locationData = locationDoc.value!.data() ?? {};
    final locationPaymentDocs = ref.watch(locationPaymentsProvider(locationId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(locationData["name"] ?? ""),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                context.push("/admin/location/$locationId/edit");
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: "Leistungen", icon: Icon(Icons.request_page)),
              Tab(text: "Infos", icon: Icon(Icons.info_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            locationPaymentDocs.when(
              data: (paymentsData) {
                final payments = paymentsData.docs.map(
                  (doc) => Payment.fromDoc(doc),
                );
                final startDate = ref.watch(paymentsStartDateProvider);
                final timespan = ref.watch(paymentsTimespanProvider);
                final Map<int, List<Payment>> dateSortedData = {};
                double maxVal = 1;
                if (payments.isNotEmpty) {
                  final timespan = ref.watch(paymentsTimespanProvider);
                  if (timespan == Timespan.day) {
                    final hoursPrefixedPayments =
                        payments
                            .map((payment) => (payment.timestamp.hour, payment))
                            .toList();
                    final int minHour =
                        hoursPrefixedPayments
                            .reduce((a, b) => a.$1 <= b.$1 ? a : b)
                            .$1;
                    final int maxHour =
                        hoursPrefixedPayments
                            .reduce((a, b) => a.$1 >= b.$1 ? a : b)
                            .$1;
                    for (int i = min(minHour, 8); i <= max(maxHour, 19); i++) {
                      dateSortedData[i] =
                          hoursPrefixedPayments
                              .where((payment) => payment.$1 == i)
                              .map((payment) => payment.$2)
                              .toList();
                    }
                  } else if (timespan == Timespan.week) {
                    final weekdayPrefixedPayments =
                        payments
                            .map(
                              (payment) => (payment.timestamp.weekday, payment),
                            )
                            .toList();
                    for (int i = 1; i <= 7; i++) {
                      dateSortedData[i] =
                          weekdayPrefixedPayments
                              .where((payment) => payment.$1 == i)
                              .map((payment) => payment.$2)
                              .toList();
                    }
                  } else if (timespan == Timespan.month) {
                    final dayPrefixedPayments =
                        payments
                            .map((payment) => (payment.timestamp.day, payment))
                            .toList();
                    for (int i = 1; i <= startDate.getMonthDayCount(); i++) {
                      dateSortedData[i] =
                          dayPrefixedPayments
                              .where((payment) => payment.$1 == i)
                              .map((payment) => payment.$2)
                              .toList();
                    }
                  }

                  if (dateSortedData.isNotEmpty) {
                    maxVal = max(
                      dateSortedData.values
                          .map(
                            (list) => list.fold(
                              0.0,
                              (total, payment) => total + payment.amount,
                            ),
                          )
                          .reduce(max),
                      1,
                    );
                  }
                }
                final sortedDates =
                    dateSortedData.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                final isScreenWide =
                    MediaQuery.of(context).size.aspectRatio > 1;

                final summaryCard = Card.outlined(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    constraints: BoxConstraints(maxHeight: 300),
                    child: Column(
                      mainAxisSize:
                          isScreenWide ? MainAxisSize.max : MainAxisSize.min,
                      crossAxisAlignment:
                          isScreenWide
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Einnahmen ${switch (timespan) {
                            Timespan.day => "${startDate.day}. ${startDate.getMonthName()}${startDate.year == DateTime.now().year ? "" : " ${startDate.year}"}",
                            Timespan.week => "KW ${startDate.weekOfYear}",
                            Timespan.month => "${startDate.getMonthName()}${startDate.year == DateTime.now().year ? "" : " ${startDate.year}"}",
                          }}",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${payments.fold(0.0, (total, element) => total + element.amount).toString()} CHF",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "+ -- % über dem Durchschnitt",
                          style: TextStyle(fontSize: 13, color: Colors.green),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Nach DialogerInnen-Anteil",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${payments.fold(0.0, (total, element) => total + element.amount * (1 - element.dialogerShare)).toStringAsFixed(2)} CHF",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                final graph = Card.outlined(
                  child: PaymentsGraph(payments: payments.toList()),
                );

                return ListView(
                  children: [
                    Card.outlined(child: PaymentsTimespanBar()),
                    isScreenWide
                        ? Row(children: [summaryCard, Expanded(child: graph)])
                        : Column(children: [summaryCard, graph]),
                    Divider(height: 30, color: Theme.of(context).primaryColor),
                    Column(
                      children:
                          payments.map((payment) {
                            final date = payment.timestamp;
                            late String datePrefix;
                            final today = DateTime.now();
                            final yesterday =
                                DateTime.fromMicrosecondsSinceEpoch(
                                  DateTime.now().millisecondsSinceEpoch -
                                      1000 * 3600 * 24,
                                );
                            if (date.year == today.year &&
                                date.month == today.month &&
                                date.day == today.day) {
                              datePrefix = "Heute";
                            } else if (date.year == yesterday.year &&
                                date.month == yesterday.month &&
                                date.day == yesterday.day) {
                              datePrefix = "Gestern";
                            } else {
                              datePrefix =
                                  "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.";
                            }
                            late Widget isPaidWidget;
                            if (payment.getPaymentStatus() ==
                                PaymentStatus.paid) {
                              isPaidWidget = getPill(
                                "Bezahlt",
                                Theme.of(context).primaryColor,
                                true,
                              );
                            } else if (payment.getPaymentStatus() ==
                                PaymentStatus.pending) {
                              isPaidWidget = getPill(
                                "Ausstehend",
                                Theme.of(context).primaryColorLight,
                                false,
                              );
                            } else if (payment.getPaymentStatus() ==
                                PaymentStatus.cancelled) {
                              isPaidWidget = getPill(
                                "Zurückgenommen",
                                Theme.of(context).cardColor,
                                false,
                              );
                            } else {
                              isPaidWidget = getPill(
                                "Keine Information",
                                Colors.grey,
                                true,
                              );
                            }
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            datePrefix,
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "${payment.amount.toString()} CHF",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        Expanded(child: isPaidWidget),
                                        IconButton(
                                          onPressed: () {
                                            context.push(
                                              "/dialoger/payment/${payment.id}/edit",
                                            );
                                          },
                                          icon: Icon(Icons.edit),
                                          tooltip: "Bearbeiten",
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text(
                                                      "Leistung löschen?",
                                                    ),
                                                    content: Text(
                                                      "Dieser Schritt kann nicht rückgängig gemacht werden",
                                                    ),
                                                    actions: [
                                                      OutlinedButton(
                                                        onPressed: () {
                                                          context.pop();
                                                        },
                                                        child: Text(
                                                          "Abbrechen",
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                "payments",
                                                              )
                                                              .doc(payment.id)
                                                              .delete();
                                                          if (context.mounted) {
                                                            context.pop();
                                                            showSnackBar(
                                                              context,
                                                              "Leistung gelöscht!",
                                                            );
                                                          }
                                                        },
                                                        child: Text("Löschen"),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                          },
                                          icon: Icon(Icons.delete),
                                          tooltip: "Löschen",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Divider(),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                );
              },
              error: (object, stackTrace) {
                print(object);
                print(stackTrace);
                return Center(
                  child: Text("Ups, hier hat etwas nicht geklappt"),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Kontakt",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  locationData["link"] != null
                      ? ClickableLink(link: locationData["link"])
                      : Text("Kein Link"),
                  locationData["email"] != null
                      ? ClickableLink(
                        link: "mailto:${locationData["email"]}",
                        label: locationData["email"],
                      )
                      : Text("Keine Email"),
                  locationData["phone"] != null
                      ? ClickableLink(
                        link: "tel:${locationData["phone"]}",
                        label: locationData["phone"],
                      )
                      : Text("Keine Email"),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Adresse",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Text(
                    "${locationData["address"]?["street"] ?? ""} ${locationData["address"]?["house_number"] ?? ""}",
                  ),
                  Text(
                    "${locationData["address"]?["postal_code"] ?? ""} ${locationData["address"]?["town"] ?? ""}",
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Notizen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Text(locationData["notes"] ?? "Keine Notizen"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final weekNumber =
        ((difference(startOfYear).inDays + startOfYear.weekday) / 7).ceil();
    return weekNumber;
  }
}
