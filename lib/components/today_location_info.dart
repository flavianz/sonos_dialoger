import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/clickable_link.dart';
import 'package:sonos_dialoger/providers/firestore_providers.dart';
import 'package:sonos_dialoger/providers/firestore_providers/location_providers.dart';

import '../app.dart';

class TodayLocationInfo extends ConsumerWidget {
  final bool isAdmin;

  const TodayLocationInfo({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySchedule = ref.watch(todayScheduleProvider);

    return todaySchedule.when(
      data: (scheduleDocs) {
        final userId = ref.watch(userProvider).value?.uid;
        if (scheduleDocs.docs.isEmpty) {
          return Center(child: Text("Heute bist du nicht eingeteilt"));
        }
        final scheduleData = scheduleDocs.docs[0].data();

        if (scheduleData["personnel_assigned"] != true) {
          return Center(child: Text("Heute bist du nicht eingeteilt"));
        }
        final assignments =
            (scheduleData["personnel"] as Map<String, dynamic>? ?? {}).entries
                .where(
                  (assignment) =>
                      (assignment.value as List? ?? []).contains(userId),
                )
                .toList();
        if (!isAdmin && assignments.isEmpty) {
          return Center(child: Text("Heute bist du nicht eingeteilt 3"));
        }
        final myAssignment =
            (scheduleData["personnel"] as Map<String, dynamic>? ?? {})
                .entries
                .first;
        String myLocationId = myAssignment.key;

        final locationDoc = ref.watch(locationProvider(myLocationId));

        return locationDoc.when(
          data:
              (location) => SingleChildScrollView(
                child: Column(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsets.only(left: 4, top: 12),
                      child: Text(
                        "Kontakt",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Divider(),
                    (location.link != null && location.link!.isNotEmpty)
                        ? ClickableLink(link: location.link!)
                        : Text("Kein Link"),
                    (location.email != null && location.email!.isNotEmpty)
                        ? ClickableLink(
                          link: "mailto:${location.email!}",
                          label: location.email!,
                          icon: Icons.mail_outline,
                        )
                        : Text("Keine Email"),
                    (location.phone != null && location.phone!.isNotEmpty)
                        ? ClickableLink(
                          link: "tel:${location.phone!}",
                          label: location.phone,
                          icon: Icons.phone,
                        )
                        : Text("Keine Telefonnummer"),
                    Padding(
                      padding: EdgeInsets.only(left: 4, top: 12),
                      child: Text(
                        "Adresse",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Divider(),
                    Text(
                      "${location.street ?? "-"} ${location.houseNumber ?? ""}",
                    ),
                    Text(
                      "${location.postalCode ?? ""} ${location.town ?? "-"}",
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 4, top: 12),
                      child: Text(
                        "Dokumente",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Divider(),
                    (location.areaOverview != null &&
                            location.areaOverview!.isNotEmpty)
                        ? ClickableLink(
                          link: location.areaOverview!,
                          icon: Icons.description_outlined,
                          label: "Flächenübersicht",
                        )
                        : Text("Keine Flächenübersicht"),
                    (location.usageRights != null &&
                            location.usageRights!.isNotEmpty)
                        ? ClickableLink(
                          link: location.usageRights!,
                          icon: Icons.description_outlined,
                          label: "Nutzungsrechte",
                        )
                        : Text("Keine Nutzungsrechte"),
                    (location.contract != null && location.contract!.isNotEmpty)
                        ? ClickableLink(
                          link: location.contract!,
                          icon: Icons.description_outlined,
                          label: "Vertrag",
                        )
                        : Text("Kein Vertrag"),
                    Padding(
                      padding: EdgeInsets.only(left: 4, top: 12),
                      child: Text(
                        "Notizen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Divider(),
                    Text(
                      (location.notes == null || location.notes!.isEmpty)
                          ? "Keine Notizen"
                          : location.notes!,
                    ),
                  ],
                ),
              ),
          error:
              (err, stack) => const Center(
                child: Text("Fehler beim Laden der Standplatzinfos"),
              ),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
      error:
          (err, stack) =>
              const Center(child: Text("Fehler beim Laden der Einteilung")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
