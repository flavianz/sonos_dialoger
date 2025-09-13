import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final dialogerDocs = ref.watch(dialogerProvider);

    if (dialogerDocs.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (dialogerDocs.hasError) {
      print(dialogerDocs.error);
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 24 : 8,
        vertical: 12,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text("Dialoger")),
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
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.delete),
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
      ),
    );
  }
}
