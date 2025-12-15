import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Einstellungen")),
      body: Column(
        children: [
          Text("Auto-Export", style: TextStyle(fontWeight: FontWeight.bold)),
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
