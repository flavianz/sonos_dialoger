import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/clickable_link.dart';
import 'package:sonos_dialoger/components/input_box.dart';

import '../../components/misc.dart';
import '../../providers.dart';

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
        Filter.and(switch (ref.watch(timespanProvider)) {
          Timespan.custom => Filter.and(
            Filter(
              "timestamp",
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                ref.watch(rangeProvider).start,
              ),
            ),
            Filter(
              "timestamp",
              isLessThanOrEqualTo: Timestamp.fromDate(
                ref.watch(rangeProvider).end,
              ),
            ),
          ),
          Timespan.month => Filter(
            "timestamp",
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(DateTime.now().year, DateTime.now().month, 1),
            ),
          ),
          Timespan.week => Filter(
            "timestamp",
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ).subtract(
                Duration(days: DateTime.now().weekday - DateTime.monday),
              ),
            ),
          ),
          Timespan.yesterday => () {
            final yesterday = DateTime.now().subtract(Duration(days: 1));
            return Filter.and(
              Filter(
                "timestamp",
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(yesterday.year, yesterday.month, yesterday.day),
                ),
              ),
              Filter(
                "timestamp",
                isLessThan: Timestamp.fromDate(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
              ),
            );
          }(),
          Timespan.today => Filter(
            "timestamp",
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
              ),
            ),
          ),
        }, Filter("location", isEqualTo: locationId)),
      )
      .orderBy("timestamp", descending: true)
      .snapshots();
});

class LocationDetailsPage extends ConsumerWidget {
  final String locationId;

  const LocationDetailsPage({super.key, required this.locationId});

  BarChartGroupData generateGroupData(
    int millis,
    List<Map<dynamic, dynamic>> payments,
  ) {
    final onceTwint = payments
        .where(
          (payment) =>
              payment["type"] == "once" && payment["method"] == "twint-fast",
        )
        .fold(0.0, (total, payment) => total + payment["amount"]);
    final onceSumup = payments
        .where(
          (payment) =>
              payment["type"] == "once" && payment["method"] == "sumup",
        )
        .fold(0.0, (total, payment) => total + payment["amount"]);
    final repeatingWithFirstPaymentTwint = payments
        .where(
          (payment) =>
              payment["type"] == "repeating" &&
              payment["has_first_payment"] == true &&
              payment["method"] == "twint-fast",
        )
        .fold(0.0, (total, payment) => total + payment["amount"]);
    final repeatingWithFirstPaymentSumup = payments
        .where(
          (payment) =>
              payment["type"] == "repeating" &&
              payment["has_first_payment"] == true &&
              payment["method"] == "sumup",
        )
        .fold(0.0, (total, payment) => total + payment["amount"]);
    final repeatingWithoutFirstPayment = payments
        .where(
          (payment) =>
              payment["type"] == "repeating" &&
              payment["has_first_payment"] != true,
        )
        .fold(0.0, (total, payment) => total + payment["amount"]);
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
            DateRangeDropdown(),
            SizedBox(width: 10),
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
                final Map<int, List<Map>> dateSortedData = {};
                double maxVal = 1;
                if (paymentsData.docs.isNotEmpty) {
                  final timespan = ref.watch(timespanProvider);
                  if (timespan == Timespan.today ||
                      timespan == Timespan.yesterday) {
                    final hoursPrefixedPayments =
                        paymentsData.docs
                            .map(
                              (doc) => (
                                ((doc.data()["timestamp"] ?? Timestamp.now())
                                        as Timestamp)
                                    .toDate()
                                    .hour,
                                doc.data(),
                              ),
                            )
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
                        paymentsData.docs
                            .map(
                              (doc) => (
                                ((doc.data()["timestamp"] ?? Timestamp.now())
                                        as Timestamp)
                                    .toDate()
                                    .weekday,
                                doc.data(),
                              ),
                            )
                            .toList();
                    for (int i = 1; i <= DateTime.now().weekday; i++) {
                      dateSortedData[i] =
                          weekdayPrefixedPayments
                              .where((payment) => payment.$1 == i)
                              .map((payment) => payment.$2)
                              .toList();
                    }
                  } else if (timespan == Timespan.month) {
                    final dayPrefixedPayments =
                        paymentsData.docs
                            .map(
                              (doc) => (
                                ((doc.data()["timestamp"] ?? Timestamp.now())
                                        as Timestamp)
                                    .toDate()
                                    .day,
                                doc.data(),
                              ),
                            )
                            .toList();
                    final int maxDay =
                        dayPrefixedPayments
                            .reduce((a, b) => a.$1 >= b.$1 ? a : b)
                            .$1;
                    for (int i = 1; i <= maxDay; i++) {
                      dateSortedData[i] =
                          dayPrefixedPayments
                              .where((payment) => payment.$1 == i)
                              .map((payment) => payment.$2)
                              .toList();
                    }
                  } else if (timespan == Timespan.custom) {
                    final dateRange = ref.watch(rangeProvider);
                    final duration =
                        dateRange.end.difference(dateRange.start).inDays;

                    final millisPrefixedPayments =
                        paymentsData.docs.map((doc) {
                          final date =
                              ((doc.data()["timestamp"] ?? Timestamp.now())
                                      as Timestamp)
                                  .toDate();
                          if (duration < 30) {
                            return (
                              DateTime(
                                date.year,
                                date.month,
                                date.day,
                              ).millisecondsSinceEpoch,
                              doc.data(),
                            );
                          } else if (duration < 140) {
                            return (
                              DateTime(
                                date.year,
                                date.month,
                                date.day - date.weekday + 1,
                              ).millisecondsSinceEpoch,
                              doc.data(),
                            );
                          } else {
                            return (
                              DateTime(
                                date.year,
                                date.month,
                              ).millisecondsSinceEpoch,
                              doc.data(),
                            );
                          }
                        }).toList();
                    DateTime startDate =
                        duration < 30
                            ? DateTime(
                              dateRange.start.year,
                              dateRange.start.month,
                              dateRange.start.day,
                            )
                            : (duration < 140
                                ? DateTime(
                                  dateRange.start.year,
                                  dateRange.start.month,
                                  dateRange.start.day -
                                      dateRange.start.weekday +
                                      1,
                                )
                                : DateTime(
                                  dateRange.start.year,
                                  dateRange.start.month,
                                ));
                    while (startDate.isBefore(dateRange.end)) {
                      dateSortedData[startDate.millisecondsSinceEpoch] =
                          millisPrefixedPayments
                              .where(
                                (payment) =>
                                    payment.$1 ==
                                    startDate.millisecondsSinceEpoch,
                              )
                              .map((payment) => payment.$2)
                              .toList();
                      if (duration < 140) {
                        startDate = startDate.add(
                          Duration(days: duration < 30 ? 1 : 7),
                        );
                      } else {
                        startDate = DateTime(
                          startDate.year,
                          startDate.month + 1,
                        );
                      }
                    }
                  }
                  if (dateSortedData.isNotEmpty) {
                    maxVal = max(
                      dateSortedData.values
                          .map(
                            (list) => list.fold(
                              0.0,
                              (total, element) => total + element["amount"],
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
                          "Einnahmen ${switch (ref.watch(timespanProvider)) {
                            Timespan.today => "heute",
                            Timespan.yesterday => "gestern",
                            Timespan.week => "diese Woche",
                            Timespan.month => "diesen Monat",
                            Timespan.custom => () {
                              final dateRange = ref.watch(rangeProvider);
                              return "${dateRange.start.day}.${dateRange.start.month}. - ${dateRange.end.day}.${dateRange.end.month}.";
                            }(),
                          }}",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${paymentsData.docs.fold(0.0, (total, element) => total + element.data()["amount"]).toString()} CHF",
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
                          "${paymentsData.docs.fold(0.0, (total, element) => total + element.data()["amount"] * (1 - (element.data()["dialoger_share"] ?? 0))).toStringAsFixed(2)} CHF",
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
                  child: Container(
                    padding: EdgeInsets.all(18),
                    constraints: BoxConstraints(maxHeight: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                final currentRange = ref.read(rangeProvider);
                                final timespan = ref.read(timespanProvider);
                                if (timespan == Timespan.today ||
                                    timespan == Timespan.yesterday ||
                                    timespan == Timespan.week) {
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: currentRange.start.subtract(
                                      Duration(
                                        days: timespan == Timespan.week ? 7 : 1,
                                      ),
                                    ),
                                    end: currentRange.end.subtract(
                                      Duration(
                                        days: timespan == Timespan.week ? 7 : 1,
                                      ),
                                    ),
                                  );
                                  ref.read(timespanProvider.notifier).state =
                                      Timespan.custom;
                                } else if (timespan == Timespan.month) {
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: DateTime(
                                      currentRange.start.year,
                                      currentRange.start.month - 1,
                                    ),
                                    end: DateTime(
                                      currentRange.end.year,
                                      currentRange.end.month - 1,
                                    ),
                                  );
                                  ref.read(timespanProvider.notifier).state =
                                      Timespan.custom;
                                } else if (timespan == Timespan.custom) {
                                  final diff = currentRange.end.difference(
                                    currentRange.start,
                                  );
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: currentRange.start.subtract(diff),
                                    end: currentRange.end.subtract(diff),
                                  );
                                }
                              },
                              icon: Icon(Icons.arrow_left),
                            ),
                            Text(switch (ref.watch(timespanProvider)) {
                              Timespan.today => "Heute",
                              Timespan.yesterday => "Gestern",
                              Timespan.week => "Diese Woche",
                              Timespan.month => "Dieser Monat",
                              Timespan.custom => () {
                                final dateRange = ref.watch(rangeProvider);
                                return "${dateRange.start.day}.${dateRange.start.month}. - ${dateRange.end.day}.${dateRange.end.month}.";
                              }(),
                            }, style: TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () {
                                final currentRange = ref.read(rangeProvider);
                                final timespan = ref.read(timespanProvider);
                                if (timespan == Timespan.today ||
                                    timespan == Timespan.yesterday ||
                                    timespan == Timespan.week) {
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: currentRange.start.add(
                                      Duration(
                                        days: timespan == Timespan.week ? 7 : 1,
                                      ),
                                    ),
                                    end: currentRange.end.add(
                                      Duration(
                                        days: timespan == Timespan.week ? 7 : 1,
                                      ),
                                    ),
                                  );
                                  ref.read(timespanProvider.notifier).state =
                                      Timespan.custom;
                                } else if (timespan == Timespan.month) {
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: DateTime(
                                      currentRange.start.year,
                                      currentRange.start.month + 1,
                                    ),
                                    end: DateTime(
                                      currentRange.end.year,
                                      currentRange.end.month + 1,
                                    ),
                                  );
                                  ref.read(timespanProvider.notifier).state =
                                      Timespan.custom;
                                } else if (timespan == Timespan.custom) {
                                  final diff = currentRange.end.difference(
                                    currentRange.start,
                                  );
                                  ref
                                      .read(rangeProvider.notifier)
                                      .state = DateTimeRange(
                                    start: currentRange.start.add(diff),
                                    end: currentRange.end.add(diff),
                                  );
                                }
                              },
                              icon: Icon(Icons.arrow_right),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Expanded(
                          child:
                              paymentsData.docs.isEmpty
                                  ? Center(child: Text("Keine Daten"))
                                  : BarChart(
                                    BarChartData(
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            interval: max(
                                              ((maxVal / 6) -
                                                          ((maxVal / 6) % 10))
                                                      .toDouble() *
                                                  2,
                                              1,
                                            ),
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: leftTitles,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(),
                                        topTitles: const AxisTitles(),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (titleData, _) {
                                              return switch (ref.watch(
                                                timespanProvider,
                                              )) {
                                                Timespan.today ||
                                                Timespan.yesterday => Text(
                                                  titleData.toString().padLeft(
                                                    2,
                                                    "0",
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Timespan.week => Text(
                                                  switch (titleData) {
                                                    2 => "Di",
                                                    3 => "Mi",
                                                    4 => "Do",
                                                    5 => "Fr",
                                                    6 => "Sa",
                                                    7 => "So",
                                                    1 || _ => "Mo",
                                                  },
                                                ),
                                                Timespan.month =>
                                                  titleData %
                                                              (DateTime.now()
                                                                          .day /
                                                                      8)
                                                                  .ceil() ==
                                                          0
                                                      ? Text(
                                                        "${titleData.toString().padLeft(2, "0")}.",
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      )
                                                      : SizedBox.shrink(),
                                                Timespan.custom => () {
                                                  final dateRange = ref.watch(
                                                    rangeProvider,
                                                  );
                                                  final duration =
                                                      dateRange.end
                                                          .difference(
                                                            dateRange.start,
                                                          )
                                                          .inDays;
                                                  return Text(
                                                    duration <= 30
                                                        ? "${DateTime.fromMillisecondsSinceEpoch(titleData.ceil()).day}."
                                                        : (duration < 140
                                                            ? "KW ${DateTime.fromMillisecondsSinceEpoch(titleData.ceil()).weekOfYear}"
                                                            : switch (DateTime.fromMillisecondsSinceEpoch(
                                                              titleData.ceil(),
                                                            ).month) {
                                                              2 => "Feb",
                                                              3 => "Mär",
                                                              4 => "Apr",
                                                              5 => "Mai",
                                                              6 => "Jun",
                                                              7 => "Jul",
                                                              8 => "Aug",
                                                              9 => "Sep",
                                                              10 => "Okt",
                                                              11 => "Nov",
                                                              12 => "Dez",
                                                              1 || _ => "Jan",
                                                            }),
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  );
                                                }(),
                                              };
                                            },
                                            reservedSize: 20,
                                          ),
                                        ),
                                      ),
                                      barGroups:
                                          sortedDates
                                              .map(
                                                (entry) => generateGroupData(
                                                  entry.key,
                                                  entry.value,
                                                ),
                                              )
                                              .toList(),
                                      gridData: FlGridData(
                                        horizontalInterval: max(
                                          ((maxVal / 6) - ((maxVal / 6) % 10))
                                              .toDouble(),
                                          1,
                                        ),
                                        show: true,
                                        getDrawingHorizontalLine:
                                            (value) => FlLine(
                                              color: Colors.grey.shade200,
                                              strokeWidth: 1,
                                            ),
                                        drawVerticalLine: false,
                                      ),
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                        ),
                        SizedBox(height: 10),
                        paymentsData.docs.isNotEmpty
                            ? Row(
                              spacing: 10,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  spacing: 3,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.amberAccent,
                                      ),
                                      height: 12,
                                      width: 12,
                                    ),
                                    Tooltip(
                                      message: "LSV ohne Erstzahlung",
                                      child: Text(
                                        "LSV",
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      spacing: 3,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: Colors.lightGreen.shade300,
                                          ),
                                          height: 12,
                                          width: 12,
                                        ),
                                        Tooltip(
                                          message:
                                              "LSV mit Erstzahlung via SumUp",
                                          child: Text(
                                            "LSV mit SumUp",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      spacing: 3,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: Colors.lightGreen.shade800,
                                          ),
                                          height: 12,
                                          width: 12,
                                        ),
                                        Tooltip(
                                          message:
                                              "LSV mit Erstzahlung via Twint",
                                          child: Text(
                                            "LSV mit Twint",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      spacing: 3,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: Colors.lightBlue.shade200,
                                          ),
                                          height: 12,
                                          width: 12,
                                        ),
                                        Tooltip(
                                          message:
                                              "Einmalige Zahlung via SumUp",
                                          child: Text(
                                            "Einmalig mit SumUp",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      spacing: 3,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: Colors.lightBlue.shade700,
                                          ),
                                          height: 12,
                                          width: 12,
                                        ),
                                        Tooltip(
                                          message:
                                              "Einmalige Zahlung via Twint",
                                          child: Text(
                                            "Einmalig mit Twint",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                );

                return ListView(
                  children: [
                    isScreenWide
                        ? Row(children: [summaryCard, Expanded(child: graph)])
                        : Column(children: [summaryCard, graph]),
                    Divider(height: 30, color: Theme.of(context).primaryColor),
                    Column(
                      children:
                          paymentsData.docs.map((paymentDoc) {
                            final data = paymentDoc.data();
                            final date =
                                ((data["timestamp"] ?? Timestamp.now())
                                        as Timestamp)
                                    .toDate();
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
                            if (data["type"] == "once" ||
                                data["has_first_payment"] == true ||
                                data["payment_status"] == "paid") {
                              isPaidWidget = getPill(
                                "Bezahlt",
                                Theme.of(context).primaryColor,
                                true,
                              );
                            } else if (data["payment_status"] == "pending") {
                              isPaidWidget = getPill(
                                "Ausstehend",
                                Theme.of(context).primaryColorLight,
                                false,
                              );
                            } else if (data["payment_status"] == "cancelled") {
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
                                            "${data["amount"].toString()} CHF",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        Expanded(child: isPaidWidget),
                                        IconButton(
                                          onPressed: () {
                                            context.push(
                                              "/dialoger/payment/${paymentDoc.id}/edit",
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
                                                              .doc(
                                                                paymentDoc.id,
                                                              )
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
