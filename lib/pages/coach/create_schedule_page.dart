import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/core/location.dart';

import '../../components/dialog_bottom_sheet.dart';
import '../admin/schedule_review_page.dart';

class CreateSchedulePage extends ConsumerStatefulWidget {
  final DateTime date;

  const CreateSchedulePage({super.key, required this.date});

  @override
  ConsumerState<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends ConsumerState<CreateSchedulePage> {
  final List<Location> locations = [];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Einteilungsanfrage ${widget.date.toExtendedFormattedDateString()}",
        ),
      ),

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
                          children: [
                            Expanded(
                              child: Text(
                                "${location.name}, ${location.town ?? "-"}",
                              ),
                            ),
                          ],
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
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 50),
            child: FilledButton(
              onPressed: () async {
                setState(() {
                  isLoading = false;
                });
                await FirebaseFirestore.instance.collection("schedules").add({
                  "creation_timestamp": FieldValue.serverTimestamp(),
                  "creator": ref.watch(userProvider).value!.uid,
                  "date": Timestamp.fromDate(widget.date),
                  "requested_locations":
                      locations.map((doc) => doc.id).toList(),
                  "reviewed": false,
                  "personnel_assigned": false,
                });
                setState(() {
                  isLoading = false;
                });
                if (context.mounted) {
                  showSnackBar(context, "Einteilungsanfrage einreichen");
                  context.pop();
                }
              },
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Anfrage einreichen"),
            ),
          ),
        ],
      ),
    );
  }
}
