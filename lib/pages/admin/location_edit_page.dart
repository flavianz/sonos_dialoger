import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/input_box.dart';

class LocationEditPage extends ConsumerStatefulWidget {
  final String locationId;
  final bool isCreate;

  const LocationEditPage({
    super.key,
    required this.locationId,
    this.isCreate = false,
  });

  @override
  ConsumerState<LocationEditPage> createState() => _LocationEditPageState();
}

final locationDocProvider = StreamProvider.family((ref, String locationId) {
  return firestore.collection("locations").doc(locationId).snapshots();
});

class _LocationEditPageState extends ConsumerState<LocationEditPage> {
  bool hasBeenInit = false;
  Map<String, dynamic> data = {};

  @override
  Widget build(BuildContext context) {
    if (!widget.isCreate) {
      final locationDoc = ref.watch(locationDocProvider(widget.locationId));
      if (locationDoc.isLoading) {
        return Scaffold(
          appBar: AppBar(title: Text("Laden...")),
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (locationDoc.hasError) {
        return Scaffold(
          appBar: AppBar(title: Text("Fehler")),
          body: handleErrorWidget(locationDoc.error, locationDoc.stackTrace),
        );
      }
      if (!hasBeenInit) {
        data = locationDoc.value!.data() ?? {};
      }
    }
    if (data["address"] == null) {
      data["address"] = {};
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCreate && (data["name"] == null || data["name"].isEmpty)
              ? "Neuer Standplatz"
              : data["name"],
        ),
      ),
      body: Column(children: [InputBox.text("Name")]),
    );
  }
}
