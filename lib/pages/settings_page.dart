import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Einstellungen")),
      body: Column(
        children: [
          FilledButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            child: Text("Abmelden"),
          ),
        ],
      ),
    );
  }
}
