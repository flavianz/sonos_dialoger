import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/dialog_bottom_sheet.dart';
import 'package:sonos_dialoger/core/location.dart';
import 'package:sonos_dialoger/providers/firestore_providers.dart';

import '../../components/misc.dart';
import '../../providers/firestore_providers/location_providers.dart';

class ScheduleReviewPage extends ConsumerStatefulWidget {
  final String scheduleId;

  const ScheduleReviewPage({super.key, required this.scheduleId});

  @override
  ConsumerState<ScheduleReviewPage> createState() => _ScheduleReviewPageState();
}

class _ScheduleReviewPageState extends ConsumerState<ScheduleReviewPage> {
  late final List<String> requestedLocationIds;
  late final List<String> addedLocationIds;
  late final List<String> removedLocationIds;

  final List<Location> additionallyFetchedLocations = [];

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
        requestedLocationIds = List<String>.from(
          (scheduleData["requested_locations"] ?? []) as List,
        );
        addedLocationIds = List<String>.from(
          (scheduleData["added_locations"] ?? []) as List,
        );
        removedLocationIds = List<String>.from(
          (scheduleData["removed_locations"] ?? []) as List,
        );
        hasBeenInit = true;
      });
    }

    final fetchedLocations = [
      ...locationsDocs.value!,
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
                  requestedLocationIds.isEmpty
                      ? SizedBox(
                        height: 50,
                        child: Center(
                          child: Text("Keine angefragten Standplätze"),
                        ),
                      )
                      : SizedBox.shrink(),
                  Column(
                    children:
                        requestedLocationIds.map((requestedId) {
                          Location? location;
                          final docList =
                              fetchedLocations
                                  .where((doc) => doc.id == requestedId)
                                  .toList();
                          if (docList.isNotEmpty) {
                            location = docList[0];
                          }
                          final bool wasRemoved = removedLocationIds.contains(
                            requestedId,
                          );
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      location == null
                                          ? "Standplatz gelöscht"
                                          : "${location.name}, ${location.town ?? "-"}",
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
                                              () => removedLocationIds.remove(
                                                requestedId,
                                              ),
                                            ),
                                      )
                                      : IconButton(
                                        tooltip: "Standplatz entfernen",
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocationIds.add(
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
                  addedLocationIds.isEmpty
                      ? SizedBox(
                        height: 50,
                        child: Center(
                          child: Text("Noch keine hinzugefügten Standplätze"),
                        ),
                      )
                      : SizedBox.shrink(),
                  Column(
                    children:
                        addedLocationIds.map((requestedId) {
                          Location? location;
                          final docList =
                              fetchedLocations
                                  .where((doc) => doc.id == requestedId)
                                  .toList();
                          if (docList.isNotEmpty) {
                            location = docList[0];
                          }
                          final bool wasRemoved = removedLocationIds.contains(
                            requestedId,
                          );
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      location == null
                                          ? "Standplatz gelöscht"
                                          : "${location.name}, ${location.town ?? "-"}",
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
                                              () => removedLocationIds.remove(
                                                requestedId,
                                              ),
                                            ),
                                      )
                                      : IconButton(
                                        tooltip: "Standplatz entfernen",
                                        icon: Icon(Icons.remove_circle_outline),
                                        onPressed:
                                            () => setState(
                                              () => removedLocationIds.add(
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
                                newLocations is List<Location> &&
                                newLocations.isNotEmpty) {
                              setState(() {
                                additionallyFetchedLocations.addAll(
                                  newLocations,
                                );
                                addedLocationIds.addAll(
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
          SizedBox(height: 10),
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
                        final finalLocations = {
                          ...requestedLocationIds,
                          ...addedLocationIds,
                        }..removeAll(removedLocationIds);

                        await FirebaseFirestore.instance
                            .collection("schedules")
                            .doc(widget.scheduleId)
                            .update({
                              "reviewed": true,
                              "removed_locations": removedLocationIds,
                              "added_locations": addedLocationIds,
                              "reviewed_at": FieldValue.serverTimestamp(),
                              "confirmed_locations": finalLocations.toList(),
                              "personnel_assigned": false,
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
  final List<Location> alreadyFetchedLocations;

  const LocationAdderDialog({super.key, required this.alreadyFetchedLocations});

  @override
  ConsumerState<LocationAdderDialog> createState() =>
      _LocationAdderDialogState();
}

class _LocationAdderDialogState extends ConsumerState<LocationAdderDialog> {
  final List<Location> selectedDocs = [];

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(allLocationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Standplätze hinzufügen", style: TextStyle(fontSize: 20)),
        Divider(color: Theme.of(context).primaryColor, height: 30),
        Expanded(
          child: locations.when(
            data: (locationsData) {
              final addableLocations = locationsData.where(
                (location) =>
                    widget.alreadyFetchedLocations
                        .where((existingDoc) => location.id == existingDoc.id)
                        .isEmpty,
              );
              if (addableLocations.isEmpty) {
                return Center(child: Text("Keine weiteren Standplätze"));
              }
              return SingleChildScrollView(
                child: Column(
                  children:
                      addableLocations.map((location) {
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
                                    "${location.name}, ${location.town ?? "-"}",
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
