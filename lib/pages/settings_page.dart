import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/user.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  FilledButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                    child: Text("Abmelden"),
                  ),
                  FilledButton.tonal(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text("Account löschen?"),
                              content: Text(
                                "Dies kann nicht rückgängig gemacht werden",
                              ),
                              actions: [
                                OutlinedButton(
                                  onPressed: () => context.pop(),
                                  child: Text("Abbrechen"),
                                ),
                                FilledButton(
                                  onPressed:
                                      () =>
                                          FirebaseAuth.instance.currentUser!
                                              .delete(),
                                  child: Text("Account löschen"),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Text("Account löschen"),
                  ),
                ],
              ),
            ],
          ),
          Center(
            child: TextButton(
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    "https://www.freeprivacypolicy.com/live/92d9391b-19b7-4c30-8ab5-1040fb401caa",
                  ),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text("Datenschutz-Erklärung"),
            ),
          ),
        ],
      ),
    );
  }
}
