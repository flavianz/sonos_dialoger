import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/basic_providers.dart';

final dialogerProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance
      .collection("users")
      .where("role", isNotEqualTo: "admin"),
);

class DialogerPage extends ConsumerWidget {
  const DialogerPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final dialogerDocs = ref.watch(dialogerProvider);

    if (dialogerDocs.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (dialogerDocs.hasError) {
      print(dialogerDocs.error);
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Dialoger"),
        actions: [
          FilledButton.icon(
            onPressed: () {
              context.push("/admin/dialoger/new");
            },
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Expanded(
            child: ListView(
              children:
                  dialogerDocs.value!.docs.map((doc) {
                    final data = doc.data();
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${data["first"]} ${data["last"]}",
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    data["role"] == "coach"
                                        ? "Coach"
                                        : "DialogerIn",
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    context.push("/admin/dialog/${doc.id}");
                                  },
                                  icon: Icon(Icons.edit),
                                  tooltip: "Bearbeiten",
                                ),
                                IconButton(
                                  onPressed: () {},
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
    );
  }
}
