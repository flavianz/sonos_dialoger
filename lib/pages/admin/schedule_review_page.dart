import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/dialog_bottom_sheet.dart';

import '../../basic_providers.dart';
import '../../components/misc.dart';

final scheduleProvider = StreamProvider.family((ref, String scheduleId) {
  return FirebaseFirestore.instance
      .collection("schedules")
      .doc(scheduleId)
      .snapshots();
});

final locationIdsProvider = Provider.family<List<dynamic>, String>((
  ref,
  scheduleId,
) {
  final scheduleAsyncValue = ref.watch(scheduleProvider(scheduleId));

  // When data is available, return the locations list, otherwise return an empty list.
  return scheduleAsyncValue.value?.data()?["requested_locations"] ?? [];
});

final requestedLocationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>((
      ref,
      String scheduleId, // Changed from List to String
    ) {
      // Watch the new provider to get the list of IDs
      final locationIds = ref.watch(locationIdsProvider(scheduleId));

      // If there are no IDs, return an empty stream to avoid an error
      if (locationIds.isEmpty) {
        return Stream.empty();
      }

      if (locationIds.length > 30) {
        throw ErrorDescription("Too many locations provided (>30)");
      }

      return FirebaseFirestore.instance
          .collection("locations")
          .where(FieldPath.documentId, whereIn: locationIds)
          .snapshots();
    });

class ScheduleReviewPage extends ConsumerStatefulWidget {
  final String scheduleId;

  const ScheduleReviewPage({super.key, required this.scheduleId});

  @override
  ConsumerState<ScheduleReviewPage> createState() => _ScheduleReviewPageState();
}

class _ScheduleReviewPageState extends ConsumerState<ScheduleReviewPage> {
  final List<String> removedLocations = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> addedLocations = [];

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider(widget.scheduleId));
    final locationsDocs = ref.watch(
      requestedLocationsProvider(widget.scheduleId),
    );
    if (schedule.isLoading || locationsDocs.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (schedule.hasError || locationsDocs.hasError) {
      print(schedule.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    final scheduleData = schedule.value!.data() ?? {};
    final locations = locationsDocs.value!.docs;

    final List<DocumentSnapshot<Map<String, dynamic>>> mergedLocations = [
      ...locations,
      ...addedLocations,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Einteilung ${parseDateTimeFromTimestamp(scheduleData["date"]).toExtendedFormattedDateString()}",
        ),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ref
                      .watch(
                        realtimeDocProvider(
                          FirebaseFirestore.instance
                              .collection("users")
                              .doc(scheduleData["creator"]),
                        ),
                      )
                      .when(
                        data:
                            (userDoc) => Text(
                              "${userDoc.data()?["first"] ?? ""} ${userDoc.data()?["last"] ?? ""}",
                            ),
                        error: (error, stackTrace) {
                          print(error);
                          print(stackTrace);
                          return Text("Fehler");
                        },
                        loading: () => Center(child: Text("Laden...")),
                      ),

                  Text(
                    parseDateTimeFromTimestamp(
                      scheduleData["creation_timestamp"],
                    ).toFormattedDateTimeString(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Angefragte Standplätze",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 10),
            Row(children: [Expanded(child: Text("Name"))]),
            Divider(height: 20, color: Theme.of(context).primaryColor),
            Column(
              children:
                  locations.map((locationDoc) {
                    final locationData = locationDoc.data();
                    final bool wasRemoved = removedLocations.contains(
                      locationDoc.id,
                    );
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${locationData["name"] ?? ""}, ${locationData["address"]?["town"] ?? ""}",
                                style: TextStyle(
                                  decoration:
                                      wasRemoved
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                              ),
                            ),
                            wasRemoved
                                ? IconButton(
                                  tooltip: "Standplatz wieder hinzufügen",
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed:
                                      () => setState(
                                        () => removedLocations.remove(
                                          locationDoc.id,
                                        ),
                                      ),
                                )
                                : IconButton(
                                  tooltip: "Standplatz entfernen",
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed:
                                      () => setState(
                                        () => removedLocations.add(
                                          locationDoc.id,
                                        ),
                                      ),
                                ),
                          ],
                        ),
                        Divider(),
                      ],
                    );
                  }).toList(),
            ),
            SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: () async {
                  final isScreenWide =
                      MediaQuery.of(context).size.aspectRatio > 1;
                  final addedLocations = await openDialogOrBottomSheet(
                    context,
                    Center(child: Text("hey")),
                  );
                },
                label: Text("Standplatz hinzufügen"),
                icon: Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
