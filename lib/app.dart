import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/pages/assignment_page.dart';

final userProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final userDataProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) {
    final userStream = ref.watch(userProvider);

    var user = userStream.value;

    if (user != null) {
      var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      return docRef.snapshots();
    } else {
      return Stream.empty();
    }
  },
);

class App extends ConsumerStatefulWidget {
  final Widget child;

  const App({super.key, required this.child});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userDataStream = ref.watch(userDataProvider);

    if (userDataStream.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userDataStream.hasError) {
      return Center(child: Text("An error occurred loading your data."));
    }

    if (userDataStream.value == null) {
      context.go("auth");
    }
    final userDataDoc = userDataStream.value!;

    if (!userDataDoc.exists) {
      return AssignmentPage();
    }

    final userData = userDataDoc.data()!;

    final role = userData["role"];

    if (!["admin", "coach", "dialog"].contains(role)) {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                spacing: 30,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dir wurden noch keine Funktion zugewiesen."),
                  Text(
                    "Wenn das ein Fehler ist, setze dich mit deinem Coach oder Admin des Vereins in Kontakt",
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    late final List<Map<String, dynamic>> destinations;

    if (role == "admin") {
      destinations = [
        {
          "icon": Icon(Icons.attach_money),
          "label": "Leistungen",
          "url": "/admin/payments",
        },
        {
          "icon": Icon(Icons.diversity_3),
          "label": "Dialoger",
          "url": "/admin/dialoger",
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/admin/settings",
        },
      ];
    } else if (role == "coach") {
      destinations = [
        {
          "icon": Icon(Icons.attach_money),
          "label": "Deine Leistungen",
          "url": "/dialoger/payments",
        },
        {
          "icon": Icon(Icons.add),
          "label": "Erfassen",
          "url": "/dialoger/payment/register",
          "barOnly": true,
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/admin/settings",
        },
      ];
    } else {
      // role = dialog
      destinations = [
        {
          "icon": Icon(Icons.attach_money),
          "label": "Deine Leistungen",
          "url": "/dialoger/payments",
        },
        {
          "icon": Icon(Icons.add),
          "label": "Erfassen",
          "url": "/dialoger/payments/register",
          "barOnly": true,
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/admin/settings",
        },
      ];
    }

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    return Scaffold(
      body:
          isScreenWide
              ? Row(
                spacing: 5,
                children: [
                  NavigationRail(
                    leading:
                        role == "coach" || role == "dialog"
                            ? FloatingActionButton.extended(
                              onPressed: () {
                                context.go("/dialoger/payments/register");
                              },
                              icon: Icon(Icons.add),
                              elevation: 0,
                              label: Text("Erfassen"),
                            )
                            : null,
                    destinations:
                        destinations
                            .where((route) => route["barOnly"] != true)
                            .map((element) {
                              return NavigationRailDestination(
                                icon: element["icon"],
                                label: Text(element["label"]),
                              );
                            })
                            .toList(),
                    selectedIndex: selectedIndex,
                    extended: true,
                    trailing: FilledButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      child: Text("Sign Out"),
                    ),
                    onDestinationSelected: (i) {
                      setState(() {
                        selectedIndex = i;
                        context.go(destinations[i]["url"]);
                      });
                    },
                  ),
                  VerticalDivider(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              )
              : Padding(padding: EdgeInsets.all(12), child: widget.child),
      bottomNavigationBar:
          isScreenWide
              ? null
              : NavigationBar(
                destinations:
                    destinations.map((element) {
                      return NavigationDestination(
                        icon: element["icon"],
                        label: element["label"],
                      );
                    }).toList(),
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) {
                  setState(() {
                    selectedIndex = i;
                    context.go(destinations[i]["url"]);
                  });
                },
                elevation: 5,
              ),
    );
  }
}
