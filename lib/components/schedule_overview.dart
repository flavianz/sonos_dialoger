import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';

import '../providers/date_ranges.dart';
import '../providers/firestore_providers.dart';
import '../providers/firestore_providers/location_providers.dart';

class ScheduleOverview extends ConsumerWidget {
  const ScheduleOverview({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    return ref
        .watch(yearSchedulesProvider)
        .when(
          data: (schedules) {
            final orderedSchedules =
                schedules.docs.map((doc) => doc.data()).toList();
            orderedSchedules.sort(
              (a, b) =>
                  (a["date"] as Timestamp).compareTo(b["date"] as Timestamp),
            );

            final Map<List<dynamic>, DateTimeRange> series = {};
            Timestamp? startDate;
            Timestamp? lastDayOfSeries;
            List<dynamic>? locationIds;
            for (final schedule in orderedSchedules) {
              final currentDate = schedule["date"] as Timestamp;
              if (startDate == null ||
                  lastDayOfSeries == null ||
                  locationIds == null) {
                startDate = currentDate;
                lastDayOfSeries = currentDate;
                locationIds =
                    (schedule["confirmed_locations"] as List<dynamic>?) ?? [];
                continue;
              }
              if (currentDate
                      .toDate()
                      .difference(lastDayOfSeries.toDate())
                      .inDays ==
                  1) {
                lastDayOfSeries = currentDate;
              } else {
                series[locationIds] = DateTimeRange(
                  start: startDate.toDate(),
                  end: lastDayOfSeries.toDate(),
                );
                startDate = currentDate;
                lastDayOfSeries = currentDate;
                locationIds = schedule["confirmed_locations"];
              }
            }
            if (startDate != null && lastDayOfSeries != null) {
              series[(orderedSchedules[orderedSchedules.length -
                          1]["confirmed_locations"]
                      as List<dynamic>?) ??
                  []] = DateTimeRange(
                start: startDate.toDate(),
                end: lastDayOfSeries.toDate(),
              );
            }

            Widget getBookingsList(
              Iterable<MapEntry<dynamic, DateTimeRange>> series,
            ) {
              return Column(
                children: [
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year - 1,
                            scheduleStartDate.month,
                            scheduleStartDate.day,
                          );
                        },
                        icon: Icon(Icons.arrow_left, size: 30),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            ref
                                .watch(scheduleStartDateProvider)
                                .year
                                .toString(),
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year + 1,
                            scheduleStartDate.month,
                            scheduleStartDate.day,
                          );
                        },
                        icon: Icon(Icons.arrow_right, size: 30),
                      ),
                    ],
                  ),
                  Divider(color: Theme.of(context).primaryColor),
                  Expanded(
                    child:
                        (series.isEmpty)
                            ? Center(
                              child: Text("Keine Einteilung in diesem Jahr"),
                            )
                            : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children:
                                    series.map((entry) {
                                      final locations = (ref
                                                  .watch(allLocationsProvider)
                                                  .value ??
                                              [])
                                          .where(
                                            (loc) =>
                                                (entry.key).contains(loc.id),
                                          );
                                      return Card.outlined(
                                        color:
                                            entry.value.start.weekOfYear ==
                                                        DateTime.now()
                                                            .weekOfYear &&
                                                    entry.value.start.year ==
                                                        DateTime.now().year
                                                ? Theme.of(
                                                  context,
                                                ).secondaryHeaderColor
                                                : null,
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          alignment: Alignment.center,
                                          child: Row(
                                            children: [
                                              Column(
                                                children: [
                                                  Text(
                                                    "KW ${entry.value.start.weekOfYear}",
                                                  ),
                                                  Text(
                                                    "${entry.value.start.toFormattedDateString()} - ${entry.value.end.toFormattedDateString()}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 0.5,
                                                height: 40,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).dividerColor,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  locations.isEmpty
                                                      ? "Unbekannter Standplatz"
                                                      : locations.first
                                                          .getName(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                  ),
                ],
              );
            }

            return getBookingsList(series.entries);
          },
          error: (object, stackTrace) {
            print(object);
            print(stackTrace);
            return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
          },
          loading: () => Center(child: CircularProgressIndicator()),
        );
  }
}
