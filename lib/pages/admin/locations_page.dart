import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../components/misc.dart';
import '../../core/user.dart';
import '../../providers/firestore_providers/location_providers.dart';

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
            (locations) => Column(
              children: [
                Divider(color: Theme.of(context).primaryColor),
                Expanded(
                  child: ListView(
                    children:
                        locations.map((location) {
                          return Column(
                            children: [
                              Tappable(
                                onTap: () {
                                  context.push(
                                    "/admin/location/${location.id}",
                                  );
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(location.name),
                                    ),
                                    Expanded(child: Text(location.town ?? "-")),
                                    Expanded(child: Text("")),
                                    SizedBox(width: 5),
                                    IconButton(
                                      onPressed: () {
                                        context.push(
                                          "/admin/location/${location.id}/edit",
                                        );
                                      },
                                      icon: Icon(Icons.edit),
                                      tooltip: "Bearbeiten",
                                    ),
                                    ref.watch(userDataProvider).value?.role ==
                                            UserRole.admin
                                        ? IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text(
                                                      "Standplatz löschen?",
                                                    ),
                                                    content: Text(
                                                      "Dieser Schritt kann nicht rückgängig gemacht werden. Leistungen an diesem Standplatz werden mit keinem Standplatz verbunden sein.",
                                                    ),
                                                    actions: [
                                                      OutlinedButton(
                                                        onPressed: () {
                                                          context.pop();
                                                        },
                                                        child: Text(
                                                          "Abbrechen",
                                                        ),
                                                      ),
                                                      FilledButton(
                                                        onPressed: () async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                "locations",
                                                              )
                                                              .doc(location.id)
                                                              .delete();
                                                          if (context.mounted) {
                                                            context.pop();
                                                            showSnackBar(
                                                              context,
                                                              "Standplatz gelöscht!",
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
                                        )
                                        : SizedBox.shrink(),
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
