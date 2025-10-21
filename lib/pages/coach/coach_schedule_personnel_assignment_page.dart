import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/basic_providers.dart';
import 'package:sonos_dialoger/components/dialog_bottom_sheet.dart';
import 'package:sonos_dialoger/components/misc.dart';

class CoachSchedulePersonnelAssignmentPage extends ConsumerStatefulWidget {
  final String scheduleId;

  const CoachSchedulePersonnelAssignmentPage({
    super.key,
    required this.scheduleId,
  });

  @override
  ConsumerState<CoachSchedulePersonnelAssignmentPage> createState() =>
      _CoachSchedulePersonnelAssignmentPageState();
}

final scheduleProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      String scheduleId,
    ) {
      return FirebaseFirestore.instance
          .collection("schedules")
          .doc(scheduleId)
          .snapshots();
    });

final locationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>((
      ref,
      String scheduleId,
    ) {
      final schedule = ref.watch(scheduleProvider(scheduleId));
      if (schedule.hasError) {
        return Stream.error(schedule.error!);
      }
      if (schedule.isLoading) {
        return Stream.empty();
      }

      final scheduleData = schedule.value?.data() ?? {};

      List<dynamic> confirmedLocations = scheduleData["confirmed_locations"];

      return FirebaseFirestore.instance
          .collection("locations")
          .where(FieldPath.documentId, whereIn: confirmedLocations)
          .snapshots();
    });

class _CoachSchedulePersonnelAssignmentPageState
    extends ConsumerState<CoachSchedulePersonnelAssignmentPage> {
  final Map<String, List<DocumentSnapshot<Map<String, dynamic>>>>
  assignedDialoguers = {};

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final dialoguers = ref.watch(
      realtimeCollectionProvider(
        FirebaseFirestore.instance
            .collection("users")
            .where("role", isNotEqualTo: "admin"),
      ),
    );
    final alreadyAssignedDialoguers = [
      for (var sublist in assignedDialoguers.values) ...sublist,
    ];
    return ref
        .watch(scheduleProvider(widget.scheduleId))
        .when(
          data: (scheduleDoc) {
            if (dialoguers.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (dialoguers.hasError) {
              print(dialoguers.error);
              return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
            }
            final dialoguerDocs = dialoguers.value!;
            final scheduleData = scheduleDoc.data() ?? {};
            final date = parseDateTimeFromTimestamp(scheduleData["date"]);

            final isNotSubmittable =
                (ref
                        .watch(locationsProvider(widget.scheduleId))
                        .when(
                          data:
                              (data) =>
                                  assignedDialoguers.length < data.docs.length,
                          error: (error, stack) => false,
                          loading: () => false,
                        ) ||
                    assignedDialoguers.values
                        .where((sublist) => sublist.isEmpty)
                        .isNotEmpty);

            return Scaffold(
              appBar: AppBar(
                forceMaterialTransparency: true,
                title: Text(
                  "Einteilung ${date.toExtendedFormattedDateString()}",
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: ref
                          .watch(locationsProvider(widget.scheduleId))
                          .when(
                            data:
                                (locationDocs) => Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ...(locationDocs.docs.map((locationDoc) {
                                      final locationData = locationDoc.data();
                                      final List<
                                        DocumentSnapshot<Map<String, dynamic>>
                                      >
                                      locationDialoguers =
                                          assignedDialoguers[locationDoc.id] ??
                                          [];
                                      return Card.outlined(
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  right: 5,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "${locationData["name"] ?? ""}, ${locationData["address"]?["town"] ?? ""}",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      locationDialoguers.length
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(height: 15),
                                              locationDialoguers.isEmpty
                                                  ? SizedBox(
                                                    height: 50,
                                                    child: Center(
                                                      child: Text(
                                                        "Noch keine Dialoger*innen eingeteilt",
                                                      ),
                                                    ),
                                                  )
                                                  : SizedBox.shrink(),
                                              Column(
                                                children:
                                                    locationDialoguers.map((
                                                      dialoguerDoc,
                                                    ) {
                                                      final dialoguerData =
                                                          dialoguerDoc.data() ??
                                                          {};
                                                      return Column(
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
                                                                "${dialoguerData["first"] ?? ""} ${dialoguerData["last"] ?? ""}",
                                                              ),
                                                              IconButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    assignedDialoguers[locationDoc
                                                                            .id]
                                                                        ?.removeWhere(
                                                                          (
                                                                            doc,
                                                                          ) =>
                                                                              doc.id ==
                                                                              dialoguerDoc.id,
                                                                        );
                                                                  });
                                                                },
                                                                icon: Icon(
                                                                  Icons
                                                                      .remove_circle_outline,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Divider(),
                                                        ],
                                                      );
                                                    }).toList(),
                                              ),
                                              Center(
                                                child: FilledButton(
                                                  onPressed: () async {
                                                    final addedDialoguers =
                                                        await openDialogOrBottomSheet(
                                                          context,
                                                          DialoguerAdderDialog(
                                                            allDialoguers:
                                                                dialoguerDocs
                                                                    .docs,
                                                            alreadyAssignedDialoguers:
                                                                alreadyAssignedDialoguers,
                                                          ),
                                                        );
                                                    if (addedDialoguers !=
                                                            null &&
                                                        addedDialoguers
                                                            is List<
                                                              DocumentSnapshot<
                                                                Map<
                                                                  String,
                                                                  dynamic
                                                                >
                                                              >
                                                            > &&
                                                        addedDialoguers
                                                            .isNotEmpty) {
                                                      setState(() {
                                                        if (!assignedDialoguers
                                                            .containsKey(
                                                              locationDoc.id,
                                                            )) {
                                                          assignedDialoguers[locationDoc
                                                                  .id] =
                                                              [];
                                                        }
                                                        assignedDialoguers[locationDoc
                                                                .id]
                                                            ?.addAll(
                                                              addedDialoguers,
                                                            );
                                                      });
                                                    }
                                                  },
                                                  child: Text(
                                                    "Dialoger*innen hinzufügen",
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList()),
                                    Divider(
                                      color: Theme.of(context).primaryColor,
                                      height: 20,
                                    ),
                                    SizedBox(height: 15),
                                    Text(
                                      "Nicht eingeteilt",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Divider(),
                                    dialoguerDocs.docs
                                            .where(
                                              (doc) =>
                                                  alreadyAssignedDialoguers
                                                      .where(
                                                        (assignedDoc) =>
                                                            doc.id ==
                                                            assignedDoc.id,
                                                      )
                                                      .isEmpty,
                                            )
                                            .isEmpty
                                        ? SizedBox(
                                          height: 50,
                                          child: Center(
                                            child: Text(
                                              "Alle Dialoger*innen eingeteilt",
                                            ),
                                          ),
                                        )
                                        : SizedBox.shrink(),
                                    Column(
                                      children:
                                          dialoguerDocs.docs
                                              .where(
                                                (doc) =>
                                                    alreadyAssignedDialoguers
                                                        .where(
                                                          (assignedDoc) =>
                                                              doc.id ==
                                                              assignedDoc.id,
                                                        )
                                                        .isEmpty,
                                              )
                                              .map((dialoguerDoc) {
                                                final dialoguerData =
                                                    dialoguerDoc.data();
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                      child: Text(
                                                        "${dialoguerData["first"] ?? ""} ${dialoguerData["last"] ?? ""}",
                                                      ),
                                                    ),
                                                    Divider(),
                                                  ],
                                                );
                                              })
                                              .toList(),
                                    ),
                                  ],
                                ),
                            error: (object, stackTrace) {
                              print(object);
                              print(stackTrace);
                              return Center(
                                child: Text(
                                  "Ups, hier hat etwas nicht geklappt",
                                ),
                              );
                            },
                            loading:
                                () =>
                                    Center(child: CircularProgressIndicator()),
                          ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 50),
                    child: FilledButton(
                      onPressed:
                          isNotSubmittable
                              ? null
                              : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                await FirebaseFirestore.instance
                                    .collection("schedules")
                                    .doc(widget.scheduleId)
                                    .update({
                                      "personnel_assigned": true,
                                      "personnel": Map.fromEntries(
                                        assignedDialoguers.entries.map(
                                          (entry) => MapEntry(
                                            entry.key,
                                            entry.value.map((doc) => doc.id),
                                          ),
                                        ),
                                      ),
                                    });
                                setState(() {
                                  isLoading = false;
                                });
                                if (context.mounted) {
                                  showSnackBar(
                                    context,
                                    "Einteilung abgeschickt",
                                  );
                                  context.pop();
                                }
                              },
                      child:
                          isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                isNotSubmittable
                                    ? "Nicht alle Standplätze belegt"
                                    : "Einteilung abschicken",
                              ),
                    ),
                  ),
                ],
              ),
            );
          },
          error: (object, stackTrace) {
            print(object);
            print(stackTrace);
            return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
          },
          loading: () => Center(child: CircularProgressIndicator()),
        );
  }
}

class DialoguerAdderDialog extends ConsumerStatefulWidget {
  final List<DocumentSnapshot<Map<String, dynamic>>> allDialoguers;
  final List<DocumentSnapshot<Map<String, dynamic>>> alreadyAssignedDialoguers;

  const DialoguerAdderDialog({
    super.key,
    required this.allDialoguers,
    required this.alreadyAssignedDialoguers,
  });

  @override
  ConsumerState<DialoguerAdderDialog> createState() =>
      _DialoguerAdderDialogState();
}

class _DialoguerAdderDialogState extends ConsumerState<DialoguerAdderDialog> {
  final List<DocumentSnapshot<Map<String, dynamic>>> selectedDocs = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Dialoger*innen hinzufügen", style: TextStyle(fontSize: 20)),
        Divider(color: Theme.of(context).primaryColor, height: 30),
        Expanded(
          child: () {
            final addableLocations = widget.allDialoguers.where(
              (doc) =>
                  widget.alreadyAssignedDialoguers
                      .where((existingDoc) => doc.id == existingDoc.id)
                      .isEmpty,
            );
            if (addableLocations.isEmpty) {
              return Center(child: Text("Keine weiteren Dialoger*innen"));
            }
            return SingleChildScrollView(
              child: Column(
                children:
                    addableLocations.map((location) {
                      final locationData = location.data() ?? {};
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Tappable(
                              onTap: () {
                                setState(() {
                                  if (!selectedDocs
                                      .where((doc) => doc.id == location.id)
                                      .isNotEmpty) {
                                    selectedDocs.add(location);
                                  } else {
                                    selectedDocs.removeWhere(
                                      (doc) => doc.id == location.id,
                                    );
                                  }
                                });
                              },
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
                                    "${locationData["first"] ?? ""} ${locationData["last"] ?? ""}",
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
            );
          }(),
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
