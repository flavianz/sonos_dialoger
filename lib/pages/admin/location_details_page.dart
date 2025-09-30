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
    print(
      "$onceTwint $onceSumup $repeatingWithFirstPaymentTwint $repeatingWithFirstPaymentSumup $repeatingWithoutFirstPayment",
    );
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
          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text("Hello World"),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: BarChart(
                          BarChartData(
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  interval: 20,
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
                                  getTitlesWidget: (millis, _) {
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                          millis.toInt(),
                                        );
                                    return Text(
                                      "${date.day.toString().padLeft(2, "0")}.${date.month.toString().padLeft(2, "0")}.",
                                      style: TextStyle(fontSize: 13),
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
                                        entry.value,
                                      ),
                                    )
                                    .toList(),
                            gridData: FlGridData(
                              horizontalInterval: 20,
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
                    ),
                  ],
                ),
              ),
            ],
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
