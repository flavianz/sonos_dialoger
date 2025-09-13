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
        body: ListView(
          children:
              dialogerDocs.value!.docs.map((doc) {
                final data = doc.data();
                return Column(
                  children: [
                    Row(children: [Text("${data["first"]} ${data["last"]}")]),
                    Divider(),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
