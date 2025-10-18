import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final data = scheduleAsyncValue.value?.data() ?? {};

  // When data is available, return the locations list, otherwise return an empty list.
  return [
    ...(data["requested_locations"] ?? []),
    ...(data["added_locations"] ?? []),
  ];
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
  late final List<dynamic> requestedLocations;
  late final List<dynamic> addedLocations;
  late final List<dynamic> removedLocations;

  final List<DocumentSnapshot<Map<String, dynamic>>>
  additionallyFetchedLocations = [];

  bool isLoading = false;
  bool hasBeenInit = false;

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
    if (!hasBeenInit) {
      setState(() {
        requestedLocations = scheduleData["requested_locations"] ?? [];
        addedLocations = scheduleData["added_locations"] ?? [];
        removedLocations = scheduleData["removed_locations"] ?? [];
        hasBeenInit = true;
      });
    }

    final fetchedLocations = [
      ...locationsDocs.value!.docs,
      ...additionallyFetchedLocations,
    ];

    final bool reviewed = scheduleData["reviewed"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Einteilung ${parseDateTimeFromTimestamp(scheduleData["date"]).toExtendedFormattedDateString()}",
        ),
        forceMaterialTransparency: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Erstellt am ${parseDateTimeFromTimestamp(scheduleData["creation_timestamp"]).toFormattedDateTimeString()}",
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Angefragte Standplätze",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Row(children: [Expanded(child: Text("Name"))]),
                  Divider(height: 20, color: Theme.of(context).primaryColor),
                  Column(
                    children:
                        requestedLocations.map((requestedId) {
                          late final Map<String, dynamic> locationData;
                          final docList =
                              fetchedLocations
                                  .where((doc) => doc.id == requestedId)
                                  .toList();
                          if (docList.isNotEmpty) {
                            locationData = docList[0].data() ?? {};
                          } else {
                            locationData = {};
                          }
                          final bool wasRemoved = removedLocations.contains(
                            requestedId,
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
                                  reviewed
                                      ? SizedBox.shrink()
                                      : wasRemoved
                                      ? IconButton(
                                        tooltip: "Standplatz wieder hinzufügen",
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocations.remove(
                                                requestedId,
                                              ),
                                            ),
                                      )
                                      : IconButton(
                                        tooltip: "Standplatz entfernen",
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocations.add(
                                                requestedId,
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
                  Text(
                    "Hinzugefügte Standplätze",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  SizedBox(height: 10),
                  Row(children: [Expanded(child: Text("Name"))]),
                  Divider(height: 20, color: Theme.of(context).primaryColor),
                  Column(
                    children:
                        addedLocations.map((requestedId) {
                          late final Map<String, dynamic> locationData;
                          final docList =
                              fetchedLocations
                                  .where((doc) => doc.id == requestedId)
                                  .toList();
                          if (docList.isNotEmpty) {
                            locationData = docList[0].data() ?? {};
                          } else {
                            locationData = {};
                          }
                          final bool wasRemoved = removedLocations.contains(
                            requestedId,
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
                                  reviewed
                                      ? SizedBox.shrink()
                                      : wasRemoved
                                      ? IconButton(
                                        tooltip: "Standplatz wieder hinzufügen",
                                        icon: Icon(Icons.add_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocations.remove(
                                                requestedId,
                                              ),
                                            ),
                                      )
                                      : IconButton(
                                        tooltip: "Standplatz entfernen",
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocations.add(
                                                requestedId,
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
                  reviewed
                      ? SizedBox.shrink()
                      : Center(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final newLocations = await openDialogOrBottomSheet(
                              context,
                              LocationAdderDialog(
                                alreadyFetchedLocations: fetchedLocations,
                              ),
                            );
                            if (newLocations != null &&
                                newLocations
                                    is List<
                                      DocumentSnapshot<Map<String, dynamic>>
                                    > &&
                                newLocations.isNotEmpty) {
                              setState(() {
                                additionallyFetchedLocations.addAll(
                                  newLocations,
                                );
                                addedLocations.addAll(
                                  newLocations.map((doc) => doc.id),
                                );
                              });
                            }
                          },
                          label: Text("Standplatz hinzufügen"),
                          icon: Icon(Icons.add),
                        ),
                      ),
                ],
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 50),
            child:
                reviewed
                    ? FilledButton.tonalIcon(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        await FirebaseFirestore.instance
                            .collection("schedules")
                            .doc(widget.scheduleId)
                            .update({
                              "reviewed": false,
                              "reviewed_at": FieldValue.delete(),
                            });
                        setState(() {
                          isLoading = false;
                        });
                      },
                      label:
                          isLoading
                              ? CircularProgressIndicator()
                              : Text("Bestätigung zurücknehmen"),
                      icon: isLoading ? null : Icon(Icons.undo),
                    )
                    : FilledButton.icon(
                      icon: isLoading ? null : Icon(Icons.check),
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        await FirebaseFirestore.instance
                            .collection("schedules")
                            .doc(widget.scheduleId)
                            .update({
                              "reviewed": true,
                              "removed_locations": removedLocations,
                              "added_locations": addedLocations,
                              "reviewed_at": FieldValue.serverTimestamp(),
                            });
                        setState(() {
                          isLoading = false;
                        });
                      },
                      label:
                          isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Einteilung bestätigen"),
                    ),
          ),
        ],
      ),
    );
  }
}

class LocationAdderDialog extends ConsumerStatefulWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> alreadyFetchedLocations;

  const LocationAdderDialog({super.key, required this.alreadyFetchedLocations});

  @override
  ConsumerState<LocationAdderDialog> createState() =>
      _LocationAdderDialogState();
}

class _LocationAdderDialogState extends ConsumerState<LocationAdderDialog> {
  final List<DocumentSnapshot<Map<String, dynamic>>> selectedDocs = [];

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(
      realtimeCollectionProvider(
        FirebaseFirestore.instance.collection("locations"),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Standplätze hinzufügen", style: TextStyle(fontSize: 20)),
        Divider(color: Theme.of(context).primaryColor, height: 30),
        Expanded(
          child: locations.when(
            data: (locationsData) {
              final addableLocations = locationsData.docs.where(
                (doc) =>
                    widget.alreadyFetchedLocations
                        .where((existingDoc) => doc.id == existingDoc.id)
                        .isEmpty,
              );
              if (addableLocations.isEmpty) {
                return Center(child: Text("Keine weiteren Standplätze"));
              }
              return SingleChildScrollView(
                child: Column(
                  children:
                      addableLocations.map((location) {
                        final locationData = location.data();
                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value:
                                        selectedDocs
                                            .where(
                                              (doc) => doc.id == location.id,
                                            )
                                            .isNotEmpty,
                                    onChanged: (newValue) {
                                      setState(() {
                                        if (newValue == true) {
                                          selectedDocs.add(location);
                                        } else {
                                          selectedDocs.removeWhere(
                                            (doc) => doc.id == location.id,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    "${locationData["name"]}, ${locationData["address"]?["town"] ?? ""}",
                                  ),
                                ],
                              ),
                            ),
                            Divider(),
                          ],
                        );
                      }).toList(),
                ),
              );
            },
            error: (object, stackTrace) {
              print(object);
              print(stackTrace);
              return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
            },
            loading: () => Center(child: CircularProgressIndicator()),
          ),
        ),
        Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text("Abbrechen"),
            ),
            FilledButton(
              onPressed:
                  selectedDocs.isNotEmpty
                      ? () => context.pop(selectedDocs)
                      : null,
              child: Text("${selectedDocs.length} hinzufügen"),
            ),
          ],
        ),
      ],
    );
  }
}
