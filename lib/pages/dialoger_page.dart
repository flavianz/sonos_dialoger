import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';

class DialogerPage extends ConsumerWidget {
  const DialogerPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final userData = ref.watch(userDataProvider);

    if (userData.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userData.hasError) {
      return Center(child: Text(userData.error!.toString()));
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isScreenWide ? 24 : 8,
        vertical: 12,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text("Dialoger")),
        body: Center(child: Text(userData.value?["first"])),
      ),
    );
  }
}
