import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';

import '../basic_providers.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  bool isLoading = false;
  String? error;

  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (!user.hasValue) {
      context.go("/auth");
      return Center();
    }
    return Scaffold(
      body: Center(
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Text(
                      "Zugriffs-Code",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    autocorrect: false,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Der Zugriffs-Code, den du erhalten hast",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  error == null
                      ? SizedBox.shrink()
                      : Text(
                        error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                  error == null ? SizedBox.shrink() : SizedBox(height: 30),
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
                                "access": passwordController.text,
                              }),
                            ).future,
                          );

                          if (result.data["result"] == true) {
                            setState(() {
                              isLoading = false;
                              error = null;
                            });
                            await ref
                                .read(userProvider)
                                .value
                                ?.getIdToken(true)
                                .then((r) => print("reloaded id token"));
                          } else {
                            setState(() {
                              isLoading = false;
                              error =
                                  "Dein Zugriffs-Code ist nicht gültig. Eventuell wurde er geändert";
                            });
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            print(e);
                            error =
                                "Ein unbekannter Fehler ist aufgetreten. Probiere es später erneut";
                          });
                        }
                      },
                      child:
                          isLoading
                              ? SizedBox(
                                height: 16,
                                width: 16,
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
    );
  }
}
