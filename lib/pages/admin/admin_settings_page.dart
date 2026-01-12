import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/providers/firestore_providers.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../components/input_box.dart';
import '../../components/misc.dart';
import '../../core/user.dart';

class AdminSettingsPage extends ConsumerStatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  ConsumerState<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends ConsumerState<AdminSettingsPage> {
  String autoExportEmail = "";
  String originalEmail = "";
  bool hasBeenInit = false;
  bool isEmailLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userData = ref.watch(userDataProvider);
    final autoExport = ref.watch(autoExportProvider);

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
          Text("Export", style: TextStyle(fontWeight: FontWeight.bold)),
          Divider(),
          autoExport.when(
            data: (autoExportDoc) {
              if (autoExportDoc.data()?["email"] == null) {
                return Text("Ups, hier hat etwas nicht geklappt");
              }

              if (!hasBeenInit) {
                setState(() {
                  autoExportEmail = autoExportDoc.data()?["email"]!;
                  originalEmail = autoExportEmail;
                  hasBeenInit = true;
                });
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 15,
                children: [
                  Expanded(
                    child: InputBox.text("Email", autoExportEmail, (value) {
                      setState(() {
                        autoExportEmail = value ?? "";
                      });
                    }),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: FilledButton(
                      onPressed:
                          autoExportEmail == originalEmail
                              ? null
                              : () async {
                                setState(() {
                                  isEmailLoading = true;
                                });
                                await autoExportDoc.reference.update({
                                  "email": autoExportEmail,
                                });
                                setState(() {
                                  originalEmail = autoExportEmail;
                                  isEmailLoading = false;
                                });
                                if (context.mounted) {
                                  showSnackBar(context, "Email aktualisiert");
                                }
                              },
                      child:
                          isEmailLoading
                              ? SizedBox(
                                height: 15,
                                width: 15,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : Text("Speichern"),
                    ),
                  ),
                ],
              );
            },
            error: errorHandling,
            loading:
                () => Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: CircularProgressIndicator(),
                  ),
                ),
          ),
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
