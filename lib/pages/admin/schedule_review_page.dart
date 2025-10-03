import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';

final scheduleProvider = StreamProvider.family(
  (ref, String scheduleId) =>
      FirebaseFirestore.instance
          .collection("schedules")
          .doc(scheduleId)
          .snapshots(),
);

final requestedLocationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, List>((
      ref,
      List locationIds,
    ) {
      if (locationIds.length > 30) {
        throw ErrorDescription("Too many locations provided (>30)");
      }
      return FirebaseFirestore.instance
          .collection("schedules")
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
  bool hasBeenInitialized = false;
  final List<DocumentSnapshot<Map<String, dynamic>>> locations = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> removals = [];
  final List<DocumentSnapshot<Map<String, dynamic>>> additions = [];

  @override
  Widget build(BuildContext context) {
    final scheduleDoc = ref.watch(scheduleProvider(widget.scheduleId));
    if (scheduleDoc.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (scheduleDoc.hasError) {
      print(scheduleDoc.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    final scheduleData = scheduleDoc.value?.data() ?? {};
    final List locationIds = scheduleData["locations"];
    print("wef");
    final requestedLocationsDocs = ref.watch(
      requestedLocationsProvider(locationIds),
    );
    if (requestedLocationsDocs.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (requestedLocationsDocs.hasError) {
      print(requestedLocationsDocs.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    print("object");
    if (!hasBeenInitialized) {
      setState(() {
        locations.addAll(requestedLocationsDocs.value!.docs);
        hasBeenInitialized = true;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Anfrage ${parseDateTime(scheduleData["date"]).toExtendedFormattedDateString()}",
        ),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        children: [
          SizedBox(height: 15),
          Text(
            "Angefragte Standplätze",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          SizedBox(height: 15),
          Column(
            children:
                locations.map((locationDoc) {
                  final locationData = locationDoc.data() ?? {};
                  return Row(
                    children: [Expanded(child: Text(locationData["name"]))],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
