import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/misc.dart';
import '../../providers/firestore_providers.dart';

class LocationsPage extends ConsumerWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final locationDocs = ref.watch(allLocationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text("Standplätze"),
        actions: [
          FilledButton.icon(
            onPressed: () {
              context.push("/admin/locations/new");
            },
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
        forceMaterialTransparency: true,
      ),
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
                              Tappable(
                                onTap: () {
                                  context.push("/admin/location/${doc.id}");
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text("${data["name"] ?? ""}"),
                                    ),
                                    Expanded(
                                      child: Text(
                                        data["address"]?["town"] ?? "",
                                      ),
                                    ),
                                    Expanded(child: Text("")),
                                    SizedBox(width: 5),
                                    IconButton(
                                      onPressed: () {
                                        context.push(
                                          "/admin/location/${doc.id}/edit",
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
