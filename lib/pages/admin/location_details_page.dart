import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/input_box.dart';

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
          "custom" => Filter.and(
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
          "all" => Filter(
            "timestamp",
            isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(0),
          ),
          "month" => Filter(
            "timestamp",
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(DateTime.now().year, DateTime.now().month, 0),
            ),
          ),
          "week" => Filter(
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
          "yesterday" => () {
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
          "today" || _ => Filter(
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
    double once,
    double repeatingWithFirstPayment,
    double repeatingWithoutFirstPayment,
  ) {
    return BarChartGroupData(
      x: millis,
      groupVertically: true,

      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: once.toDouble(),
          color: Colors.red,
          width: 15,
        ),
        BarChartRodData(
          fromY: once,
          toY: once + repeatingWithFirstPayment,
          color: Colors.amberAccent,
          width: 15,
        ),
        BarChartRodData(
          fromY: once + repeatingWithFirstPayment,
          toY: once + repeatingWithFirstPayment + repeatingWithoutFirstPayment,
          color: Colors.green,
          width: 15,
        ),
      ],
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

    return Scaffold(
      appBar: AppBar(
        title: Text(locationData["name"] ?? ""),
        actions: [DateRangeDropdown()],
      ),
      body: locationPaymentDocs.when(
        data: (paymentsData) {
          final Map<int, List<Map>> dateSortedData = {};
          final dateRange = ref.watch(rangeProvider);
          DateTime date = dateRange.start;
          while (!date.isAfter(dateRange.end)) {
            dateSortedData[date.millisecondsSinceEpoch] = [];
            date = date.add(Duration(days: 1));
          }
          for (final paymentDoc in paymentsData.docs) {
            final date =
                ((paymentDoc.data()["timestamp"] ?? Timestamp.now())
                        as Timestamp)
                    .toDate();
            final dateMillis =
                DateTime(
                  date.year,
                  date.month,
                  date.day,
                ).millisecondsSinceEpoch;
            if (dateSortedData[dateMillis] == null) {
              dateSortedData[dateMillis] = [];
            }
            dateSortedData[dateMillis]?.add(paymentDoc.data());
          }
          final dates =
              dateSortedData.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
          return BarChart(
            BarChartData(
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (millis, _) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        millis.toInt(),
                      );
                      return Text(
                        "${date.day.toString().padLeft(2, "0")}.${date.month.toString().padLeft(2, "0")}.",
                      );
                    },
                    reservedSize: 20,
                  ),
                ),
              ),
              barGroups:
                  dates
                      .map(
                        (entry) => generateGroupData(
                          entry.key,
                          entry.value
                              .where((payment) => payment["type"] == "once")
                              .fold(
                                0.0,
                                (total, payment) => total + payment["amount"],
                              ),
                          entry.value
                              .where(
                                (payment) =>
                                    payment["type"] == "repeating" &&
                                    payment["has_first_payment"] == true,
                              )
                              .fold(
                                0.0,
                                (total, payment) => total + payment["amount"],
                              ),
                          entry.value
                              .where(
                                (payment) =>
                                    payment["type"] == "repeating" &&
                                    payment["has_first_payment"] != true,
                              )
                              .fold(
                                0.0,
                                (total, payment) => total + payment["amount"],
                              ),
                        ),
                      )
                      .toList(),
            ),
          );
        },
        error: (object, stackTrace) {
          print(object);
          print(stackTrace);
          return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
        },
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
