import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/input_box.dart';

import '../providers/basic_providers.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  bool isLoading = false;
  String? error;
  String password = "";

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (!user.hasValue) {
      context.go("/auth");
      return Center();
    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Fast geschafft!", style: TextStyle(fontSize: 24)),
                        Text("Wir brauchen nur noch deinen Zugriffs-Code"),
                        SizedBox(height: 30),
                        InputBox.text(
                          "Zugriffs-Code",
                          password,
                          (str) => setState(() {
                            password = str ?? "";
                          }),
                          hint: "Der Zugriffs-Code, den du erhalten hast",
                        ),
                        SizedBox(height: 30),
                        error == null
                            ? SizedBox.shrink()
                            : Text(
                              error!,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),

                        error == null
                            ? SizedBox.shrink()
                            : SizedBox(height: 30),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 40),
                          child: FilledButton(
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                                error = null;
                              });

                              try {
                                final result = await ref.read(
                                  callableProvider(
                                    CallableProviderArgs("assignUser", {
                                      "access": password,
                                    }),
                                  ).future,
                                );

                                if (result.data["result"] == true) {
                                  if (context.mounted) {
                                    setState(() {
                                      isLoading = false;
                                      error = null;
                                    });
                                  }
                                  print("trying to reload tokens");
                                  ref
                                      .read(userProvider)
                                      .value
                                      ?.getIdToken(true)
                                      .then((r) => print("reloaded id token"));
                                } else {
                                  if (context.mounted) {
                                    setState(() {
                                      isLoading = false;
                                      error =
                                          "Dein Zugriffs-Code ist nicht gültig. Eventuell wurde er geändert";
                                    });
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                    print(e);
                                    error =
                                        "Ein unbekannter Fehler ist aufgetreten. Probiere es später erneut";
                                  });
                                }
                              }
                            },
                            child:
                                isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text("Verknüpfen"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: FilledButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
              },
              child: Text("Ausloggen"),
            ),
          ),
        ],
      ),
    );
  }
}
