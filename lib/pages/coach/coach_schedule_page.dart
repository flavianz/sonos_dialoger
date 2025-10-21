import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../basic_providers.dart';
import '../../components/misc.dart';
import '../../providers.dart';
import '../dialoger/dialoger_schedule_page.dart';

final confirmedSchedulesProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance
      .collection("schedules")
      .where(
        Filter.and(
          Filter("reviewed", isEqualTo: true),
          Filter("personnel_assigned", isEqualTo: false),
        ),
      )
      .orderBy("date"),
);

final coachSchedulesProvider = StreamProvider((ref) {
  final scheduleTimespan = ref.watch(scheduleTimespanProvider);
  final scheduleStartDate = ref.watch(scheduleStartDateProvider);

  late final DateTime endDate;
  if (scheduleTimespan == ScheduleTimespan.day) {
    endDate = scheduleStartDate.add(Duration(days: 1));
  } else if (scheduleTimespan == ScheduleTimespan.week) {
    endDate = scheduleStartDate.add(Duration(days: 7));
  } else {
    endDate = DateTime(scheduleStartDate.year, scheduleStartDate.month + 1);
  }

  return firestore
      .collection("schedules")
      .where(
        Filter.and(
          Filter(
            "date",
            isGreaterThanOrEqualTo: Timestamp.fromDate(scheduleStartDate),
          ),
          Filter("date", isLessThan: Timestamp.fromDate(endDate)),
        ),
      )
      .snapshots();
});

final coachScheduleLocationsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>((ref) {
      final schedules = ref.watch(coachSchedulesProvider);
      if (schedules.isLoading) {
        return Stream.empty();
      }
      if (schedules.hasError) {
        return Stream.error(schedules.error ?? "Unknown error");
      }
      final scheduleDocs = schedules.value!.docs;
      final locationIds = flatten(
        scheduleDocs.map((doc) {
          return (doc.data()["personnel"] as Map<String, dynamic>).keys;
        }),
      );
      final locations = ref.watch(
        queryByIdsProvider(
          QueryByIdsArgs(
            queryKey: "locations",
            ids: locationIds.toSet().toList(),
          ),
        ),
      );
      if (locations.isLoading) {
        return Stream.empty();
      }
      if (locations.hasError) {
        return Stream.error(locations.error ?? "Unknown error");
      }
      return Stream.value(locations.value);
    });

class CoachSchedulePage extends ConsumerWidget {
  const CoachSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Einteilung"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: "Kalender"),
              Tab(icon: Icon(Icons.new_releases_outlined), text: "Bestätigt"),
            ],
          ),
          actions: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 150),
              child: DropdownButtonFormField(
                initialValue: ref.watch(scheduleTimespanProvider),
                decoration: InputDecoration(
                  hintText: "Zeitraum",
                  border: InputBorder.none,
                ),
                items: [
                  DropdownMenuItem(
                    value: ScheduleTimespan.day,
                    child: Text("Tag"),
                  ),
                  DropdownMenuItem(
                    value: ScheduleTimespan.week,
                    child: Text("Woche"),
                  ),
                  DropdownMenuItem(
                    value: ScheduleTimespan.month,
                    child: Text("Monat"),
                  ),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    ref.read(scheduleTimespanProvider.notifier).state =
                        newValue;
                    if (newValue == ScheduleTimespan.week) {
                      ref.read(scheduleStartDateProvider.notifier).state =
                          scheduleStartDate.getWeekStart();
                    } else if (newValue == ScheduleTimespan.month) {
                      ref.read(scheduleStartDateProvider.notifier).state =
                          scheduleStartDate.getMonthStart();
                    }
                  }
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (scheduleTimespan == ScheduleTimespan.day) {
                          ref.read(scheduleStartDateProvider.notifier).state =
                              scheduleStartDate.subtract(Duration(days: 1));
                        } else if (scheduleTimespan == ScheduleTimespan.week) {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year,
                            scheduleStartDate.month,
                            scheduleStartDate.day - 7,
                          );
                        } else {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year,
                            scheduleStartDate.month - 1,
                          );
                        }
                      },
                      icon: Icon(Icons.arrow_left, size: 30),
                    ),
                    Text(switch (scheduleTimespan) {
                      ScheduleTimespan.day =>
                        scheduleStartDate.toExtendedFormattedDateString() +
                            (scheduleStartDate.year != DateTime.now().year
                                ? (" ${scheduleStartDate.year.toString()}")
                                : ""),
                      ScheduleTimespan.week => () {
                        return "${scheduleStartDate.getWeekStart().toExtendedFormattedDateString()} - ${scheduleStartDate.getWeekStart().add(Duration(days: 6)).toExtendedFormattedDateString()}${scheduleStartDate.year != DateTime.now().year ? (" ${scheduleStartDate.year.toString()}") : ""}";
                      }(),
                      ScheduleTimespan.month =>
                        scheduleStartDate.getMonthName() +
                            (scheduleStartDate.year != DateTime.now().year
                                ? (" ${scheduleStartDate.year.toString()}")
                                : ""),
                    }, style: TextStyle(fontSize: 20)),
                    IconButton(
                      onPressed: () {
                        if (scheduleTimespan == ScheduleTimespan.day) {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = scheduleStartDate.add(Duration(days: 1));
                        } else if (scheduleTimespan == ScheduleTimespan.week) {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year,
                            scheduleStartDate.month,
                            scheduleStartDate.day + 7,
                          );
                          print(
                            ref
                                .read(scheduleStartDateProvider)
                                .toFormattedDateTimeString(),
                          );
                        } else {
                          ref
                              .read(scheduleStartDateProvider.notifier)
                              .state = DateTime(
                            scheduleStartDate.year,
                            scheduleStartDate.month + 1,
                          );
                        }
                      },
                      icon: Icon(Icons.arrow_right, size: 30),
                    ),
                  ],
                ),
                Divider(color: Theme.of(context).primaryColor),
                SizedBox(height: 15),
              ],
            ),
            ref
                .watch(confirmedSchedulesProvider)
                .when(
                  data:
                      (scheduleRequestDocs) => Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 16, bottom: 4),
                            child: Row(
                              children: [
                                Expanded(child: Text("Datum")),
                                Expanded(child: Text("Erstellt am")),
                              ],
                            ),
                          ),
                          Divider(color: Theme.of(context).primaryColor),

                          Expanded(
                            child:
                                scheduleRequestDocs.docs.isEmpty
                                    ? Center(
                                      child: Text(
                                        "Keine bestätigten Einteilungen",
                                      ),
                                    )
                                    : ListView(
                                      children:
                                          scheduleRequestDocs.docs.map((
                                            scheduleRequestDoc,
                                          ) {
                                            final scheduleRequestData =
                                                scheduleRequestDoc.data();
                                            final date =
                                                ((scheduleRequestData["date"] ??
                                                            Timestamp.now())
                                                        as Timestamp)
                                                    .toDate();
                                            final creationTimestamp =
                                                ((scheduleRequestData["creation_timestamp"] ??
                                                            Timestamp.now())
                                                        as Timestamp)
                                                    .toDate();
                                            return Tappable(
                                              onTap: () {
                                                context.push(
                                                  "/coach/schedule/personnel_assignment/${scheduleRequestDoc.id}",
                                                );
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 5,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        date.toExtendedFormattedDateString(),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        creationTimestamp
                                                            .toFormattedDateTimeString(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                          ),
                        ],
                      ),
                  error: (object, stackTrace) {
                    print(object);
                    print(stackTrace);
                    return Center(
                      child: Text("Ups, hier hat etwas nicht geklappt"),
                    );
                  },
                  loading: () => Center(child: CircularProgressIndicator()),
                ),
          ],
        ),
      ),
    );
  }
}
