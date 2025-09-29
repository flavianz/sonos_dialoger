import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../basic_providers.dart';
import '../../components/misc.dart';

final locationsProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance.collection("locations"),
);

class LocationsPage extends ConsumerWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final locationDocs = ref.watch(locationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text("Standplätze")),
      body: locationDocs.when(
        data:
            (data) => Column(
              children: [
                Divider(color: Theme.of(context).primaryColor),
                Expanded(
                  child: ListView(
                    children:
                        data.docs.map((doc) {
                          final data = doc.data();
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  context.push("/admin/location/${doc.id}");
                                },
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${data["name"] ?? ""}, ${data["address"]?["town"] ?? ""}",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      IconButton(
                                        onPressed: () {
                                          context.push(
                                            "/dialoger/payment/${doc.id}/edit",
                                          );
                                        },
                                        icon: Icon(Icons.edit),
                                        tooltip: "Bearbeiten",
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text(
                                                    "Leistung löschen?",
                                                  ),
                                                  content: Text(
                                                    "Dieser Schritt kann nicht rückgängig gemacht werden",
                                                  ),
                                                  actions: [
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        context.pop();
                                                      },
                                                      child: Text("Abbrechen"),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              "payments",
                                                            )
                                                            .doc(doc.id)
                                                            .delete();
                                                        if (context.mounted) {
                                                          context.pop();
                                                          showSnackBar(
                                                            context,
                                                            "Leistung gelöscht!",
                                                          );
                                                        }
                                                      },
                                                      child: Text("Löschen"),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                        icon: Icon(Icons.delete),
                                        tooltip: "Löschen",
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
                ),
              ],
            ),
        error: (object, stackTrace) {
          print(object);
          print(stackTrace);
          return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
        },
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
