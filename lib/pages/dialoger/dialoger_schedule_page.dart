import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/providers.dart';

enum ScheduleTimespan { day, week, month }

final scheduleTimespanProvider = StateProvider<ScheduleTimespan>(
  (ref) => ScheduleTimespan.week,
);

final scheduleStartDateProvider = StateProvider<DateTime>((ref) {
  final scheduleTimespan = ref.read(scheduleTimespanProvider);
  final now = DateTime.now();
  if (scheduleTimespan == ScheduleTimespan.day) {
    return now.getDayStart();
  } else if (scheduleTimespan == ScheduleTimespan.week) {
    return now.getWeekStart();
  } else {
    return now.getMonthStart();
  }
});

final schedulesProvider = StreamProvider((ref) {
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
          Filter("personnel_assigned", isEqualTo: true),
        ),
      )
      .snapshots();
});

final scheduleLocationsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>((ref) {
      final schedules = ref.watch(schedulesProvider);
      if (schedules.isLoading) {
        return Stream.empty();
      }
      if (schedules.hasError) {
        return Stream.error(schedules.error ?? "Unknown error");
      }
      final scheduleDocs = schedules.value!.docs;
      final locationIds = flatten(
        scheduleDocs.map((doc) {
          return doc.data()["confirmed_locations"] ?? [];
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

class DialogerSchedulePage extends ConsumerWidget {
  const DialogerSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    final schedules = ref.watch(schedulesProvider);
    final locationDocs = ref.watch(scheduleLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Einteilung"),
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
                  ref.read(scheduleTimespanProvider.notifier).state = newValue;
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
      body: Column(
        children: [
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (scheduleTimespan == ScheduleTimespan.day) {
                    ref
                        .read(scheduleStartDateProvider.notifier)
                        .state = scheduleStartDate.subtract(Duration(days: 1));
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
          Expanded(
            child: schedules.when(
              data: (scheduleDocs) {
                if (locationDocs.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (locationDocs.hasError) {
                  print(locationDocs.error);
                  print(locationDocs.stackTrace);
                  return Center(
                    child: Text("Ups, hier hat etwas nicht geklappt"),
                  );
                }
                final locations = locationDocs.value!;

                if (scheduleDocs.docs.isEmpty) {
                  return Center(child: Text("Noch keine Einteilung erstellt"));
                }

                if (scheduleTimespan == ScheduleTimespan.day) {
                  final scheduleData = scheduleDocs.docs[0].data();
                  final Map<String, dynamic> assignments =
                      scheduleData["personnel"] ?? {};

                  final userId = ref.watch(userProvider).value?.uid;

                  if (!flatten(assignments.values).contains(userId)) {
                    return Center(
                      child: Text("An diesem Tag bist du nicht eingeteilt"),
                    );
                  }

                  final String myLocationId =
                      assignments.entries
                          .where(
                            (entry) => (entry.value as List).contains(userId),
                          )
                          .toList()[0]
                          .key;
                  final filteredLocations =
                      locations.where((doc) => doc.id == myLocationId).toList();
                  if (filteredLocations.isEmpty) {
                    return Center(
                      child: Text("Ups, hier hat etwas nicht geklappt"),
                    );
                  }
                  final myLocationDoc = filteredLocations[0];
                  final myLocationData = myLocationDoc.data();
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${myLocationData["name"]}, ${myLocationData["address"]?["town"]}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${myLocationData["address"]?["street"] ?? ""} ${myLocationData["address"]?["house_number"] ?? ""}",
                        ),
                        Text(
                          "${myLocationData["address"]?["postal_code"] ?? ""} ${myLocationData["address"]?["town"] ?? ""}",
                        ),
                        SizedBox(height: 30),
                        Text(
                          "Eingeteilte Dialoger*innen",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(color: Theme.of(context).primaryColor),
                        ref
                            .watch(
                              queryByIdsProvider(
                                QueryByIdsArgs(
                                  queryKey: "users",
                                  ids: assignments[myLocationId] as List,
                                ),
                              ),
                            )
                            .when(
                              data:
                                  (userDocs) => Column(
                                    children:
                                        userDocs.map((userDoc) {
                                          final userData = userDoc.data();
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 3,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${userData["first"] ?? ""} ${userData["last"] ?? ""}",
                                                ),
                                                Divider(),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              error: errorHandling,
                              loading: loadingHandling,
                            ),
                      ],
                    ),
                  );
                } else if (scheduleTimespan == ScheduleTimespan.week ||
                    scheduleTimespan == ScheduleTimespan.month) {
                  return SingleChildScrollView(
                    child: Column(
                      children:
                          (scheduleTimespan == ScheduleTimespan.week
                                  ? [1, 2, 3, 4, 5, 6, 7]
                                  : List<int>.generate(
                                    DateTime(
                                      scheduleStartDate.year,
                                      scheduleStartDate.month + 1,
                                      0,
                                    ).day,
                                    (i) => 1 + i,
                                  ))
                              .map((weekdayOrDayOfTheMonth) {
                                final date =
                                    scheduleTimespan == ScheduleTimespan.week
                                        ? DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          scheduleStartDate.day -
                                              scheduleStartDate.weekday +
                                              weekdayOrDayOfTheMonth,
                                        )
                                        : DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          weekdayOrDayOfTheMonth,
                                        );
                                final dateFilteredScheduleDocs =
                                    scheduleDocs.docs.where((doc) {
                                      final scheduleDate =
                                          parseDateTimeFromTimestamp(
                                            doc.data()["date"],
                                          );
                                      return date.isSameDate(scheduleDate);
                                    }).toList();

                                return Card.outlined(
                                  color:
                                      date.isSameDate(DateTime.now())
                                          ? Theme.of(
                                            context,
                                          ).secondaryHeaderColor
                                          : null,
                                  child: Tappable(
                                    onTap: () {
                                      ref
                                          .read(
                                            scheduleTimespanProvider.notifier,
                                          )
                                          .state = ScheduleTimespan.day;
                                      ref
                                          .read(
                                            scheduleStartDateProvider.notifier,
                                          )
                                          .state = date.getDayStart();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                date.getWeekdayAbbreviation(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                date.toFormattedDateString(),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 50,
                                            child: VerticalDivider(width: 20),
                                          ),
                                          () {
                                            if (dateFilteredScheduleDocs
                                                .isEmpty) {
                                              return Center(
                                                child: Text(
                                                  "Noch keine Einteilung erstellt",
                                                ),
                                              );
                                            }
                                            final scheduleData =
                                                dateFilteredScheduleDocs[0]
                                                    .data();
                                            final Map<String, dynamic>
                                            assignments =
                                                scheduleData["personnel"] ?? {};

                                            final userId =
                                                ref
                                                    .watch(userProvider)
                                                    .value
                                                    ?.uid;

                                            if (!flatten(
                                              assignments.values,
                                            ).contains(userId)) {
                                              return Center(
                                                child: Text(
                                                  "An diesem Tag bist du nicht eingeteilt",
                                                ),
                                              );
                                            }

                                            final String myLocationId =
                                                assignments.entries
                                                    .where(
                                                      (entry) =>
                                                          (entry.value as List)
                                                              .contains(userId),
                                                    )
                                                    .toList()[0]
                                                    .key;
                                            final filteredLocations =
                                                locations
                                                    .where(
                                                      (doc) =>
                                                          doc.id ==
                                                          myLocationId,
                                                    )
                                                    .toList();
                                            if (filteredLocations.isEmpty) {
                                              return Center(
                                                child: Text(
                                                  "Ups, hier hat etwas nicht geklappt",
                                                ),
                                              );
                                            }
                                            final myLocationDoc =
                                                filteredLocations[0];
                                            final myLocationData =
                                                myLocationDoc.data();
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${myLocationData["name"]}",
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),

                                                Text(
                                                  "${myLocationData["address"]?["street"] ?? ""} ${myLocationData["address"]?["house_number"] ?? ""}, ${myLocationData["address"]?["postal_code"] ?? ""} ${myLocationData["address"]?["town"] ?? ""}",
                                                ),
                                              ],
                                            );
                                          }(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  );
                } else {
                  return Center();
                }
              },
              error: errorHandling,
              loading: loadingHandling,
            ),
          ),
        ],
      ),
    );
  }
}
