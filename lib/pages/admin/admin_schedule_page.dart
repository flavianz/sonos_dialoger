import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/basic_providers.dart';
import 'package:sonos_dialoger/components/misc.dart';

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
        ),
        body: TabBarView(
          children: [
            Center(),
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
