import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/schedule_timespan_dropdown.dart';

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
          return doc.data()["reviewed"] == true
              ? (doc.data()["confirmed_locations"] ?? [])
              : (doc.data()["requested_locations"] ?? []);
        }),
      );

      return Stream.fromFuture(
        ref.read(
          queryByIdsProvider(
            QueryByIdsArgs(
              queryKey: "locations",
              ids: locationIds.toSet().toList(),
            ),
          ).future,
        ),
      );
    });

class CoachSchedulePage extends ConsumerWidget {
  const CoachSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

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
          actions: [ScheduleTimespanDropdown()],
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                SizedBox(height: 15),
                TimespanDateSwitcher(),
                Divider(color: Theme.of(context).primaryColor),
                SizedBox(height: 15),
                Expanded(
                  child: ref
                      .watch(schedulesProvider)
                      .when(
                        data: (coachSchedulesDocs) {
                          if (scheduleTimespan == ScheduleTimespan.day) {
                            if (coachSchedulesDocs.docs.isEmpty) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Noch keine Einteilung erstellt"),
                                  SizedBox(height: 15),
                                  FilledButton.icon(
                                    onPressed: () {
                                      context.push(
                                        "/coach/schedules/new/${scheduleStartDate.year}/${scheduleStartDate.month}/${scheduleStartDate.day}",
                                      );
                                    },
                                    icon: Icon(Icons.add),
                                    label: Text("Einteilung erstellen"),
                                  ),
                                ],
                              );
                            }
                            final coachScheduleDoc = coachSchedulesDocs.docs[0];
                            final coachScheduleData = coachScheduleDoc.data();
                            if (coachScheduleData["reviewed"] != true) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Status"),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.shade100,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.access_time, size: 17),
                                            Text(
                                              "Standplätze noch nicht bestätigt",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Angefragt am"),
                                      Text(
                                        parseDateTimeFromTimestamp(
                                          coachScheduleData["creation_timestamp"],
                                        ).toFormattedDateTimeString(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Angefragte Standplätze",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  ref
                                      .watch(scheduleLocationsProvider)
                                      .when(
                                        data: (locationDocs) {
                                          return SingleChildScrollView(
                                            child: Column(
                                              children:
                                                  (coachScheduleData["requested_locations"]
                                                          as List)
                                                      .map((locationId) {
                                                        final filteredDocs =
                                                            locationDocs!
                                                                .where(
                                                                  (doc) =>
                                                                      doc.id ==
                                                                      locationId,
                                                                )
                                                                .toList();
                                                        if (filteredDocs
                                                            .isEmpty) {
                                                          return Column(
                                                            children: [
                                                              Text(
                                                                "Unbekannter Standplatz",
                                                              ),
                                                            ],
                                                          );
                                                        }
                                                        final locationData =
                                                            filteredDocs[0]
                                                                .data();
                                                        return Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "${locationData["name"]}, ${locationData["address"]?["town"]}",
                                                            ),
                                                            Divider(),
                                                          ],
                                                        );
                                                      })
                                                      .toList(),
                                            ),
                                          );
                                        },
                                        error: errorHandling,
                                        loading: loadingHandling,
                                      ),
                                ],
                              );
                            } else if (coachScheduleData["reviewed"] == true &&
                                coachScheduleData["personnel_assigned"] !=
                                    true) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Status"),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.info_outline, size: 17),
                                            Text(
                                              "Standplätze bestätigt",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Angefragt am"),
                                      Text(
                                        parseDateTimeFromTimestamp(
                                          coachScheduleData["creation_timestamp"],
                                        ).toFormattedDateTimeString(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Bestätigte Standplätze",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Expanded(
                                    child: ref
                                        .watch(scheduleLocationsProvider)
                                        .when(
                                          data: (locationDocs) {
                                            return SingleChildScrollView(
                                              child: Column(
                                                children:
                                                    (coachScheduleData["confirmed_locations"]
                                                            as List)
                                                        .map((locationId) {
                                                          final filteredDocs =
                                                              locationDocs!
                                                                  .where(
                                                                    (doc) =>
                                                                        doc.id ==
                                                                        locationId,
                                                                  )
                                                                  .toList();
                                                          if (filteredDocs
                                                              .isEmpty) {
                                                            return Column(
                                                              children: [
                                                                Text(
                                                                  "Unbekannter Standplatz",
                                                                ),
                                                              ],
                                                            );
                                                          }
                                                          final locationData =
                                                              filteredDocs[0]
                                                                  .data();
                                                          return Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${locationData["name"]}, ${locationData["address"]?["town"]}",
                                                              ),
                                                              Divider(),
                                                            ],
                                                          );
                                                        })
                                                        .toList(),
                                              ),
                                            );
                                          },
                                          error: errorHandling,
                                          loading: loadingHandling,
                                        ),
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: 50),
                                    child: FilledButton(
                                      onPressed: () {
                                        context.push(
                                          "/coach/schedule/personnel_assignment/${coachScheduleDoc.id}",
                                        );
                                      },
                                      child: Text(
                                        "Jetzt Dialoger*innen einteilen",
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Status"),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 15,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Icon(Icons.check, size: 17),
                                            Text(
                                              "Dialoger*innen eingeteilt",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Angefragt am"),
                                      Text(
                                        parseDateTimeFromTimestamp(
                                          coachScheduleData["creation_timestamp"],
                                        ).toFormattedDateTimeString(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "Standplätze",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Expanded(
                                    child: ref
                                        .watch(scheduleLocationsProvider)
                                        .when(
                                          data: (locationDocs) {
                                            final userDocsProvider = ref.watch(
                                              queryByIdsProvider(
                                                QueryByIdsArgs(
                                                  queryKey: "users",
                                                  ids:
                                                      flatten(
                                                        (coachScheduleData["personnel"]
                                                                as Map)
                                                            .values,
                                                      ).toSet().toList(),
                                                ),
                                              ),
                                            );
                                            if (userDocsProvider.isLoading) {
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            }
                                            if (userDocsProvider.hasError) {
                                              print(userDocsProvider.error);
                                              print(
                                                userDocsProvider.stackTrace,
                                              );
                                              return Center(
                                                child: Text(
                                                  "Ups, hier hat etwas nicht geklappt",
                                                ),
                                              );
                                            }
                                            final userDocs =
                                                userDocsProvider.value ?? [];
                                            return SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children:
                                                    (coachScheduleData["confirmed_locations"]
                                                            as List)
                                                        .map((locationId) {
                                                          final filteredDocs =
                                                              locationDocs!
                                                                  .where(
                                                                    (doc) =>
                                                                        doc.id ==
                                                                        locationId,
                                                                  )
                                                                  .toList();
                                                          if (filteredDocs
                                                              .isEmpty) {
                                                            return Card.outlined(
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      16,
                                                                    ),
                                                                child: Text(
                                                                  "Unbekannter Standplatz",
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                          final locationDoc =
                                                              filteredDocs[0];
                                                          final locationData =
                                                              locationDoc
                                                                  .data();
                                                          return Card.outlined(
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    16,
                                                                  ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        "${locationData["name"]}, ${locationData["address"]?["town"]}",
                                                                        style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        (coachScheduleData["personnel"]?[locationId]
                                                                                    as List? ??
                                                                                [])
                                                                            .length
                                                                            .toString(),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Divider(),
                                                                  ...(coachScheduleData["personnel"]?[locationId]
                                                                              as List? ??
                                                                          [])
                                                                      .map((
                                                                        userId,
                                                                      ) {
                                                                        final filteredUserDocs =
                                                                            userDocs
                                                                                .where(
                                                                                  (
                                                                                    doc,
                                                                                  ) =>
                                                                                      doc.id ==
                                                                                      userId,
                                                                                )
                                                                                .toList();
                                                                        if (filteredUserDocs
                                                                            .isEmpty) {
                                                                          return Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                "Unbekannt",
                                                                              ),
                                                                              Divider(),
                                                                            ],
                                                                          );
                                                                        }
                                                                        final userDoc =
                                                                            filteredUserDocs[0];
                                                                        return Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              "${userDoc.data()["first"]} ${userDoc.data()["last"]}",
                                                                            ),
                                                                            Divider(),
                                                                          ],
                                                                        );
                                                                      }),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        })
                                                        .toList(),
                                              ),
                                            );
                                          },
                                          error: errorHandling,
                                          loading: loadingHandling,
                                        ),
                                  ),
                                ],
                              );
                            }
                          } else if (scheduleTimespan ==
                                  ScheduleTimespan.week ||
                              scheduleTimespan == ScheduleTimespan.month) {
                            return ListView.builder(
                              itemCount:
                                  scheduleTimespan == ScheduleTimespan.week
                                      ? 7
                                      : DateTime(
                                        scheduleStartDate.year,
                                        scheduleStartDate.month + 1,
                                        0,
                                      ).day,
                              itemBuilder: (BuildContext context, int index) {
                                final date =
                                    scheduleTimespan == ScheduleTimespan.week
                                        ? DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          scheduleStartDate.day -
                                              scheduleStartDate.weekday +
                                              index +
                                              1,
                                        )
                                        : DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          index + 1,
                                        );
                                final dateFilteredScheduleDocs =
                                    coachSchedulesDocs.docs.where((doc) {
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
                                      final currentTimespan = scheduleTimespan;
                                      final currentStartDate =
                                          scheduleStartDate;

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
                                      context.push("./").then((_) {
                                        ref
                                            .read(
                                              scheduleTimespanProvider.notifier,
                                            )
                                            .state = currentTimespan;
                                        ref
                                            .read(
                                              scheduleStartDateProvider
                                                  .notifier,
                                            )
                                            .state = currentStartDate;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
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
                                                final children = [
                                                  Text("Keine Einteilung"),
                                                  FilledButton.icon(
                                                    icon: Icon(Icons.add),
                                                    onPressed: () {
                                                      context.push(
                                                        "/coach/schedules/new/${date.year}/${date.month}/${date.day}",
                                                      );
                                                    },
                                                    label: Text(
                                                      "Jetzt erstellen",
                                                    ),
                                                  ),
                                                ];
                                                return Row(
                                                  spacing: 10,
                                                  children: children,
                                                );
                                              }
                                              final scheduleData =
                                                  dateFilteredScheduleDocs[0]
                                                      .data();
                                              if (scheduleData["reviewed"] !=
                                                  true) {
                                                return Row(
                                                  spacing: 10,
                                                  children: [
                                                    Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            minHeight: 25,
                                                            minWidth: 25,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .redAccent
                                                                .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.access_time,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Standplätze noch nicht bestätigt",
                                                        ),
                                                        Text(
                                                          "${((scheduleData["requested_locations"] as List?) ?? []).length} Standplätze angefragt",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              } else if (scheduleData["reviewed"] ==
                                                      true &&
                                                  scheduleData["personnel_assigned"] !=
                                                      true) {
                                                return Row(
                                                  spacing: 10,
                                                  children: [
                                                    Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            minHeight: 25,
                                                            minWidth: 25,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .amberAccent
                                                                .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.info_outline,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Standplätze bestätigt",
                                                        ),
                                                        Text(
                                                          "${((scheduleData["confirmed_locations"] as List?) ?? []).length} Standplätze",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              } else if (scheduleData["reviewed"] ==
                                                      true &&
                                                  scheduleData["personnel_assigned"] ==
                                                      true) {
                                                return Row(
                                                  spacing: 10,
                                                  children: [
                                                    Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            minHeight: 25,
                                                            minWidth: 25,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.check,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "Einteilung abgeschlossen",
                                                        ),
                                                        Text(
                                                          "${flatten(((scheduleData["personnel"] as Map?) ?? {}).values).length} Dialoger*innen in ${((scheduleData["confirmed_locations"] as List?) ?? []).length} Standplätze eingeteilt",
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              }
                                              final Map<String, dynamic>
                                              assignments =
                                                  scheduleData["personnel"] ??
                                                  {};
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

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [Row()],
                                              );
                                            }(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(child: Text("unim"));
                          }
                        },
                        error: errorHandling,
                        loading: loadingHandling,
                      ),
                ),
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
