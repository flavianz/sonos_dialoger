import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/input_box.dart';
import 'package:sonos_dialoger/components/misc.dart';

class LocationEditPage extends ConsumerStatefulWidget {
  final String locationId;
  final bool isCreate;

  const LocationEditPage({
    super.key,
    this.locationId = "",
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
  bool isLoading = false;

  final nameController = TextEditingController();
  final streetController = TextEditingController();
  final houseNumberController = TextEditingController();
  final postalCodeController = TextEditingController();
  final townController = TextEditingController();
  final linkController = TextEditingController();
  final notesController = TextEditingController();

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
        if (data["address"] == null) {
          data["address"] = {};
        }
        hasBeenInit = true;
      }
    } else {
      if (!hasBeenInit) {
        data["address"] = {};
        hasBeenInit = true;
      }
    }

    nameController.text = data["name"] ?? "";
    streetController.text = data["address"]["street"] ?? "";
    houseNumberController.text = data["address"]["house_number"] ?? "";
    postalCodeController.text = data["address"]["postal_code"] ?? "";
    townController.text = data["address"]["town"] ?? "";
    linkController.text = data["link"] ?? "";
    notesController.text = data["notes"] ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCreate && (data["name"] == null || data["name"].isEmpty)
              ? "Neuer Standplatz"
              : data["name"] ?? "",
        ),
        forceMaterialTransparency: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InputBox.textControlled(
                    "Name",
                    nameController,
                    hint: "Name des Standplatzes",
                  ),
                  InputBox.textControlled(
                    "Link",
                    linkController,
                    hint: "Link zum Standplatz",
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Adresse",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  InputBox.textControlled(
                    "Strasse",
                    streetController,
                    hint: "Adresse: Strasse",
                  ),
                  InputBox.textControlled(
                    "Hausnummmer",
                    houseNumberController,

                    hint: "Adresse: Hausnummer",
                  ),
                  InputBox.textControlled(
                    "Postleitzahl",
                    postalCodeController,
                    hint: "Adresse: Postleitzahl",
                  ),
                  InputBox.textControlled(
                    "Gemeinde",
                    townController,
                    hint: "Adresse: Gemeinde",
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Notizen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Notizen",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: notesController,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5),
          Row(
            spacing: 5,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 50),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      nameController.text = data["name"] ?? "";
                      linkController.text = data["link"] ?? "";
                      streetController.text = data["address"]["street"] ?? "";
                      houseNumberController.text =
                          data["address"]["house_number"] ?? "";
                      postalCodeController.text =
                          data["address"]["postal_code"] ?? "";
                      townController.text = data["address"]["town"] ?? "";
                      notesController.text = data["notes"] ?? "";
                    });
                  },
                  child: Text("Zurücksetzen"),
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 50),
                  child: FilledButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      final writeData = {
                        "name": nameController.text,
                        "link": linkController.text,
                        "notes": notesController.text,
                        "address": {
                          "street": streetController.text,
                          "house_number": houseNumberController.text,
                          "postal_code": postalCodeController.text,
                          "town": townController.text,
                        },
                      };
                      if (widget.isCreate) {
                        await firestore.collection("locations").add(writeData);
                      } else {
                        await firestore
                            .collection("locations")
                            .doc(widget.locationId)
                            .update(writeData);
                      }
                      setState(() {
                        isLoading = false;
                      });
                      if (context.mounted) {
                        if (widget.isCreate) {
                          showSnackBar(context, "Standplatz erstellt");
                        } else {
                          showSnackBar(context, "Änderungen gespeichert");
                        }
                        context.pop();
                      }
                    },
                    child:
                        isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Speichern"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
