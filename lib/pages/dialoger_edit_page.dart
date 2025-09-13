import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/basic_providers.dart';
import 'package:sonos_dialoger/components/input_box.dart';

class DialogerEditPage extends ConsumerStatefulWidget {
  final String userId;
  final bool creating;

  const DialogerEditPage({
    super.key,
    required this.userId,
    this.creating = false,
  });

  @override
  ConsumerState<DialogerEditPage> createState() => _DialogerEditPageState();
}

class _DialogerEditPageState extends ConsumerState<DialogerEditPage> {
  String firstName = "";
  String lastName = "";
  String? role;
  bool areInputsInitialized = false;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(
      staticDocProvider(
        FirebaseFirestore.instance.collection("users").doc(widget.userId),
      ),
    );

    if (doc.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (doc.hasError) {
      if (kDebugMode) {
        print(doc.error.toString());
      }
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }

    final data = doc.value!.data()!;

    if (!areInputsInitialized) {
      setState(() {
        firstName = data["first"] ?? "";
        lastName = data["last"] ?? "";
        role = data["role"];
        areInputsInitialized = true;
      });
    }
    final inputs = {"first": firstName, "last": lastName, "role": role};

    final changes = Map.fromEntries(
      inputs.entries.where((entry) => data[entry.key] != entry.value),
    );

    void saveData() async {
      setState(() {
        isLoading = true;
      });
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId);
      if (widget.creating) {
        await docRef.set(inputs);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("DialogerIn erstellt")));
        }
      } else {
        await docRef.update(changes);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Änderungen gespeichert!")));
        }
      }
      if (context.mounted) {
        context.pop();
      }
      setState(() {
        isLoading = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("${data["first"]} ${data["last"]} bearbeiten"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                InputBox.text(
                  "Vorname",
                  firstName,
                  (str) => setState(() {
                    firstName = str ?? "";
                  }),
                  hint: "Vornamen eingeben",
                ),
                InputBox.text(
                  "Nachname",
                  lastName,
                  (str) => setState(() {
                    lastName = str ?? "";
                  }),
                  hint: "Nachname eingeben",
                ),
                InputBox(
                  title: "Rolle",
                  widget: DropdownButtonFormField(
                    value: role,
                    decoration: InputDecoration(
                      hintText: "Wähle eine Rolle",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: "coach", child: Text("Coach")),
                      DropdownMenuItem(
                        value: "dialog",
                        child: Text("DialogerIn"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        role = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          Row(
            spacing: 10,
            children: [
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    if (changes.isEmpty) {
                      context.pop();
                      return;
                    }
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Bearbeiten abbrechen?"),
                            content: Text(
                              "Nicht gespeicherte Änderungen gehen verloren",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  context.pop();
                                },
                                child: Text("Weiter bearbeiten"),
                              ),
                              FilledButton(
                                onPressed: () {
                                  context.pop();
                                  context.pop();
                                },
                                child: Text("Abbrechen"),
                              ),
                            ],
                          ),
                    );
                  },
                  child: Text("Abbrechen"),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed:
                        widget.creating
                            ? (changes.containsKey("role") ? saveData : null)
                            : (changes.isEmpty ? null : saveData),
                    child:
                        isLoading
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                            : Text(widget.creating ? "Erstellen" : "Speichern"),
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
