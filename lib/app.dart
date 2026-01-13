import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/core/user.dart';
import 'package:sonos_dialoger/pages/assignment_page.dart';

final firestore = FirebaseFirestore.instance;

final userProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map((user) {
    if (user != null) {
      print("refreshed user token");
      user.getIdToken(true);
    }
    return user;
  }),
);

final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>>((
  ref,
) {
  final userStream = ref.watch(userProvider);
  if (userStream.value != null) {
    userStream.value!.getIdToken(true);
  }

  var user = userStream.value;

  if (user != null) {
    var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    return docRef.snapshots();
  } else {
    return Stream.empty();
  }
});

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
    final userDataStream = ref.watch(userDocProvider);

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

    final userData = SonosUser.fromDoc(userDataDoc);

    if (userData.role == null) {
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

    if (userData.role == UserRole.admin) {
      destinations = [
        {
          "icon": Icon(Icons.request_page),
          "label": "Leistungen",
          "url": "/admin/payments",
        },
        {
          "icon": Icon(Icons.diversity_3),
          "label": "Dialoger",
          "url": "/admin/dialoger",
        },
        {
          "icon": Icon(Icons.assignment),
          "label": "Einteilung",
          "url": "/admin/schedules",
        },
        {
          "icon": Icon(Icons.place),
          "label": "Standplätze",
          "url": "/admin/locations",
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/admin/settings",
        },
      ];
    } else if (userData.role == UserRole.coach) {
      destinations = [
        {
          "icon": Icon(Icons.request_page),
          "label": "Leistungen",
          "url": "/dialoger/payments",
        },
        {
          "icon": Icon(Icons.query_stats),
          "label": "Statistiken",
          "url": "/dialoger/stats",
        },
        {
          "icon": Icon(Icons.assignment),
          "label": "Einteilung",
          "url": "/coach/schedules",
        },
        {
          "icon": Icon(Icons.add),
          "label": "Erfassen",
          "url": "/dialoger/payments/register",
          "barOnly": true,
        },
        {
          "icon": Icon(Icons.place),
          "label": "Standplätze",
          "url": "/admin/locations",
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/dialog/settings",
        },
      ];
    } else {
      // role = dialog
      destinations = [
        {
          "icon": Icon(Icons.request_page),
          "label": "Leistungen",
          "url": "/dialoger/payments",
        },
        {
          "icon": Icon(Icons.query_stats),
          "label": "Statistiken",
          "url": "/dialoger/stats",
        },
        {
          "icon": Icon(Icons.add),
          "label": "Erfassen",
          "url": "/dialoger/payments/register",
          "barOnly": true,
        },
        {
          "icon": Icon(Icons.assignment),
          "label": "Einteilung",
          "url": "/dialog/schedules",
        },
        {
          "icon": Icon(Icons.settings),
          "label": "Einstellungen",
          "url": "/dialog/settings",
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
                        userData.role != UserRole.admin
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
                      child: Text("Abmelden"),
                    ),
                    onDestinationSelected: (i) {
                      setState(() {
                        selectedIndex = i;
                        context.go(
                          destinations
                              .where((route) => route["barOnly"] != true)
                              .toList()[i]["url"],
                        );
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

Widget handleErrorWidget(error, stackTrace) {
  print(error);
  print(stackTrace);
  return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
}
