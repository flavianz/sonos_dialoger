import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  bool isLoading = false;
  String? error;

  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                  Text("Wir brauchen nur noch einige Daten von dir"),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Text(
                      "Access-Code",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: passwordController,
                    autocorrect: false,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Access-Code, den du erhalten hast",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Text(
                      "Vorname",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      hintText: "Dein Vorname",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    child: Text(
                      "Nachname",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      hintText: "Dein Nachname",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  error == null
                      ? SizedBox.shrink()
                      : Text(error!, style: TextStyle(color: Colors.red)),
                  error == null ? SizedBox.shrink() : SizedBox(height: 30),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 40),
                    child: FilledButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          await FirebaseFirestore.instance
                              .collection("users")
                              .add({
                                "access": passwordController.text,
                                "first": firstNameController.text,
                                "last": lastNameController.text,
                              });
                        } on FirebaseException catch (e) {
                          if (e.code == "permission-denied") {
                            error =
                                "Dein Access-Code ist nicht gültig. Eventuell wurde er geändert";
                          }
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      },
                      child:
                          isLoading
                              ? CircularProgressIndicator()
                              : Text("Beitreten"),
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
