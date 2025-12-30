import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../core/user.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userData = ref.watch(userDataProvider);

    if (user.hasError || userData.hasError) {
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }
    if (user.isLoading || userData.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text("Einstellungen")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Auto-Export", style: TextStyle(fontWeight: FontWeight.bold)),
          Divider(),
          SizedBox(height: 15),
          Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Eingeloggt als "),
              Text(
                user.value!.email ?? "unbekannt",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Deine Rolle"),
              Text(switch (userData.value!.role) {
                UserRole.admin => "Admin",
                UserRole.coach => "Coach",
                UserRole.dialog => "Dialoger",
                _ => "Keine Rolle",
              }, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              child: Text("Abmelden"),
            ),
          ),
        ],
      ),
    );
  }
}
