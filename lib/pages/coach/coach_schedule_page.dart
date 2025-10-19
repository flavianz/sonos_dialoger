import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../basic_providers.dart';
import '../../components/misc.dart';

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

class CoachSchedulePage extends ConsumerWidget {
  const CoachSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Einteilung"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.new_releases_outlined), text: "Bestätigt"),
              Tab(icon: Icon(Icons.calendar_month), text: "Kalender"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ref
                .watch(confirmedSchedulesProvider)
                .when(
              data:
                  (scheduleRequestDocs) =>
                  Column(
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
                      Divider(color: Theme
                          .of(context)
                          .primaryColor),

                      Expanded(
                        child: scheduleRequestDocs.docs.isEmpty
                            ? Center(
                          child: Text("Keine bestätigten Einteilungen"),)
                            : ListView(
                          children:
                          scheduleRequestDocs.docs.map((scheduleRequestDoc,) {
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
                                  "/coach/schedule/personnel_assignment/${scheduleRequestDoc
                                      .id}",
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
            Center(),
          ],
        ),
      ),
    );
  }
}
