import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/basic_providers.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/components/timespan_dropdowns.dart';

import '../../app.dart';
import '../../providers.dart';
import '../../providers/date_ranges.dart';
import '../coach/coach_schedule_page.dart';
import '../dialoger/dialoger_schedule_page.dart';

final scheduleRequestsProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance
      .collection("schedules")
      .where("reviewed", isEqualTo: false)
      .orderBy("date"),
);

class AdminSchedulePage extends ConsumerWidget {
  const AdminSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Einteilung"),
          forceMaterialTransparency: true,
          bottom: TabBar(
            tabs: [
              Tab(text: "Kalender", icon: Icon(Icons.calendar_month)),
              Tab(text: "Anfragen", icon: Icon(Icons.new_releases_outlined)),
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
                          if (scheduleTimespan == Timespan.day) {
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
                                  Expanded(
                                    child: ref
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
                                  ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: 50),
                                    child: FilledButton(
                                      onPressed: () {
                                        context.push(
                                          "/admin/schedule-review/${coachScheduleDoc.id}",
                                        );
                                      },
                                      child: Text("Jetzt Standplätze prüfen"),
                                    ),
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
                          } else if (scheduleTimespan == Timespan.week ||
                              scheduleTimespan == Timespan.month) {
                            return ListView.builder(
                              itemCount:
                                  scheduleTimespan == Timespan.week
                                      ? 7
                                      : DateTime(
                                        scheduleStartDate.year,
                                        scheduleStartDate.month + 1,
                                        0,
                                      ).day,
                              itemBuilder: (BuildContext context, int index) {
                                final date =
                                    scheduleTimespan == Timespan.week
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
                                          .state = Timespan.day;
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
                                                  Text(
                                                    "Noch keine Einteilung erstellt",
                                                  ),
                                                ];
                                                return context.isScreenWide
                                                    ? Row(
                                                      spacing: 10,
                                                      children: children,
                                                    )
                                                    : Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      spacing: 5,
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
                .watch(scheduleRequestsProvider)
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
                                      child: Text("Keine Einteilungsanfragen"),
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
                                            return Column(
                                              children: [
                                                Tappable(
                                                  onTap: () {
                                                    context.push(
                                                      "/admin/schedule-review/${scheduleRequestDoc.id}",
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 5,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            date.toFormattedDateString(),
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
                                                ),
                                                Divider(),
                                              ],
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
