import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  final betweenSpace = 0;

  BarChartGroupData generateGroupData(
    int x,
    double once,
    double repeatingWithFirstPayment,
    double repeatingWithoutFirstPayment,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(fromY: 0, toY: once, color: Colors.red, width: 15),
        BarChartRodData(
          fromY: once + betweenSpace,
          toY: once + betweenSpace + repeatingWithFirstPayment,
          color: Colors.amberAccent,
          width: 15,
        ),
        BarChartRodData(
          fromY: once + betweenSpace + repeatingWithFirstPayment + betweenSpace,
          toY:
              once +
              betweenSpace +
              repeatingWithFirstPayment +
              betweenSpace +
              repeatingWithoutFirstPayment,
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
      appBar: AppBar(title: Text(locationData["name"] ?? "")),
      body: locationPaymentDocs.when(
        data:
            (data) => BarChart(
              BarChartData(
                barGroups: [
                  generateGroupData(0, 2, 3, 2),
                  generateGroupData(1, 2, 5, 1.7),
                  generateGroupData(2, 1.3, 3.1, 2.8),
                  generateGroupData(3, 3.1, 4, 3.1),
                  generateGroupData(4, 0.8, 3.3, 3.4),
                  generateGroupData(5, 2, 5.6, 1.8),
                  generateGroupData(6, 1.3, 3.2, 2),
                  generateGroupData(7, 2.3, 3.2, 3),
                  generateGroupData(8, 2, 4.8, 2.5),
                  generateGroupData(9, 1.2, 3.2, 2.5),
                  generateGroupData(10, 1, 4.8, 3),
                  generateGroupData(11, 2, 4.4, 2.8),
                ],
              ),
            ),
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
