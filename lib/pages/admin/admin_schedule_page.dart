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
              Tab(text: "Anfragen", icon: Icon(Icons.new_releases_outlined)),
              Tab(text: "Kalender", icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
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
                                Expanded(child: Text("Ersteller")),
                                Expanded(child: Text("Erstellt am")),
                              ],
                            ),
                          ),
                          Divider(color: Theme.of(context).primaryColor),
                          Expanded(
                            child: ListView(
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
                                          "/admin/schedule-review/${scheduleRequestDoc.id}",
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
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
                                                  child: ref
                                                      .watch(
                                                        realtimeDocProvider(
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                "users",
                                                              )
                                                              .doc(
                                                                scheduleRequestData["creator"],
                                                              ),
                                                        ),
                                                      )
                                                      .when(
                                                        data:
                                                            (userDoc) => Text(
                                                              "${userDoc.data()?["first"] ?? ""} ${userDoc.data()?["last"] ?? ""}",
                                                            ),
                                                        error: (
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          print(error);
                                                          print(stackTrace);
                                                          return Text("");
                                                        },
                                                        loading:
                                                            () => Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
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
                                          Divider(),
                                        ],
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
