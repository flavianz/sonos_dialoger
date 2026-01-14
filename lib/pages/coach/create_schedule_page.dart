import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/core/location.dart';
import 'package:sonos_dialoger/utils.dart';

import '../../components/dialog_bottom_sheet.dart';
import '../admin/schedule_review_page.dart';

class CreateSchedulePage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateSchedulePage({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends ConsumerState<CreateSchedulePage> {
  final List<Location> locations = [];

  bool isLoading = false;
  bool hasBeenInit = false;

  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    if (!hasBeenInit) {
      setState(() {
        startDate = widget.startDate;
        endDate = widget.endDate;
        hasBeenInit = true;
      });
    }
    String title;
    if (startDate == null || endDate == null) {
      title = "Einteilungsanfrage";
    } else if (startDate!.isSameDate(endDate!)) {
      title = "Einteilungsanfrage ${startDate!.toFormattedDateString()}";
    } else {
      title =
          "Einteilung ${startDate?.toFormattedDateString()} - ${endDate?.toFormattedDateString()}";
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: Theme.of(context).primaryColor, height: 30),
          Expanded(
            child: Column(
              children: [
                locations.isEmpty
                    ? SizedBox(
                      height: 50,
                      child: Center(child: Text("Noch keine Standplätze")),
                    )
                    : SizedBox.shrink(),
                ...locations.map((location) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [Expanded(child: Text(location.getName()))],
                        ),
                      ),
                      Divider(),
                    ],
                  );
                }),
                Center(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final newLocations = await openDialogOrBottomSheet(
                        context,
                        LocationAdderDialog(alreadyFetchedLocations: locations),
                      );
                      if (newLocations != null) {
                        setState(() {
                          locations.addAll(newLocations);
                        });
                      }
                    },
                    label: Text("Standplätze hinzufügen"),
                    icon: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Center(
            child: Text(
              "Achtung! Bestehende Einteilungen in diesem Zeitraum werden überschrieben.",
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            spacing: 10,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 50),
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1900),
                        lastDate: endDate == null ? DateTime(2200) : endDate!,
                      );
                      if (newDate != null) {
                        setState(() {
                          startDate = newDate;
                        });
                      }
                    },
                    child: Text(
                      startDate == null
                          ? "-"
                          : "${startDate!.getWeekdayAbbreviation()}, ${startDate!.toExtendedFormattedDateString()}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Text("bis"),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 50),
                  child: FilledButton.tonal(
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        firstDate:
                            startDate == null ? DateTime(1900) : startDate!,
                        lastDate: DateTime(2200),
                      );
                      if (newDate != null) {
                        setState(() {
                          endDate = newDate;
                        });
                      }
                    },
                    child: Text(
                      endDate == null
                          ? "-"
                          : "${endDate!.getWeekdayAbbreviation()}, ${endDate!.toExtendedFormattedDateString()}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 50),
            child: FilledButton(
              onPressed:
                  startDate == null ||
                          endDate == null ||
                          endDate!.difference(startDate!).inDays >= 7
                      ? null
                      : () async {
                        setState(() {
                          isLoading = true;
                        });
                        if (startDate!.isSameDate(endDate!)) {
                          await FirebaseFirestore.instance
                              .collection("schedules")
                              .add({
                                "creation_timestamp":
                                    FieldValue.serverTimestamp(),
                                "creator": ref.watch(userProvider).value!.uid,
                                "date": Timestamp.fromDate(startDate!),
                                "requested_locations":
                                    locations.map((doc) => doc.id).toList(),
                                "reviewed": false,
                                "personnel_assigned": false,
                              });
                        } else {
                          final scheduleGroupId = generateFirestoreKey();
                          DateTime tempDate = startDate!;
                          int count = 0; // safety measure

                          final batch = FirebaseFirestore.instance.batch();

                          while (!tempDate.isSameDate(endDate!.addDays(1)) &&
                              !tempDate.isAfter(endDate!.addDays(2)) &&
                              count <
                                  9 /* limit a bit too generous on purpose to avoid off by one errors*/ ) {
                            batch.set(
                              FirebaseFirestore.instance
                                  .collection("schedules")
                                  .doc(),
                              {
                                "creation_timestamp":
                                    FieldValue.serverTimestamp(),
                                "creator": ref.watch(userProvider).value!.uid,
                                "date": Timestamp.fromDate(tempDate),
                                "requested_locations":
                                    locations.map((doc) => doc.id).toList(),
                                "reviewed": false,
                                "personnel_assigned": false,
                                "group_id": scheduleGroupId,
                              },
                            );
                            tempDate = tempDate.addDays(1);
                            count++;
                          }
                          await batch.commit();
                        }

                        setState(() {
                          isLoading = false;
                        });
                        if (context.mounted) {
                          showSnackBar(
                            context,
                            "Einteilungsanfrage einreichen",
                          );
                          context.pop();
                        }
                      },
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                        (startDate == null || endDate == null)
                            ? "Zeitraum wählen"
                            : (endDate!.difference(startDate!).inDays >= 7
                                ? "Maximal 7 Tage"
                                : "Anfrage einreichen"),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
