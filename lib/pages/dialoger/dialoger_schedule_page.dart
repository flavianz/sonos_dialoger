import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/app.dart';
import 'package:sonos_dialoger/components/clickable_link.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/components/timespan_dropdowns.dart';
import 'package:sonos_dialoger/providers.dart';

import '../../providers/date_ranges.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/firestore_providers/location_providers.dart';

class DialogerSchedulePage extends ConsumerWidget {
  const DialogerSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);

    final dialogerSchedules = ref.watch(personnelAssignedSchedulesProvider);
    final dialogerLocationDocs = ref.watch(
      personnelAssignedSchedulesLocationsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Einteilung"),
        actions: [ScheduleTimespanDropdown()],
      ),
      body: Column(
        children: [
          SizedBox(height: 15),
          TimespanDateSwitcher(),
          Divider(color: Theme.of(context).primaryColor),
          SizedBox(height: 15),
          Expanded(
            child: dialogerSchedules.when(
              data: (scheduleDocs) {
                if (dialogerLocationDocs.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (dialogerLocationDocs.hasError) {
                  print("werwe");
                  print(dialogerLocationDocs.error);
                  print(dialogerLocationDocs.stackTrace);
                  return Center(
                    child: Text("Ups, hier hat etwas nicht geklappt"),
                  );
                }
                final locations = dialogerLocationDocs.value!;

                if (scheduleDocs.docs.isEmpty) {
                  return Center(child: Text("Noch keine Einteilung erstellt"));
                }

                if (scheduleTimespan == Timespan.day) {
                  final scheduleData = scheduleDocs.docs[0].data();
                  final Map<String, dynamic> assignments =
                      scheduleData["personnel"] ?? {};

                  final userId = ref.watch(userProvider).value?.uid;

                  if (!flatten(assignments.values).contains(userId)) {
                    return Center(
                      child: Text("An diesem Tag bist du nicht eingeteilt"),
                    );
                  }

                  final String myLocationId =
                      assignments.entries
                          .where(
                            (entry) => (entry.value as List).contains(userId),
                          )
                          .toList()[0]
                          .key;
                  final filteredLocations =
                      locations.where((doc) => doc.id == myLocationId).toList();
                  final myLocation =
                      filteredLocations.isEmpty ? null : filteredLocations[0];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        myLocation == null
                            ? Text(
                              "Unbekannter Standplatz",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : Column(
                              children: [
                                Text(
                                  "${myLocation.name}, ${myLocation.town ?? "-"}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${myLocation.street ?? "-"} ${myLocation.houseNumber ?? ""}",
                                ),
                                Text(
                                  "${myLocation.postalCode ?? ""} ${myLocation.town ?? "-"}",
                                ),
                                SizedBox(height: 5),
                                (myLocation.link != null &&
                                        myLocation.link!.isNotEmpty)
                                    ? ClickableLink(link: myLocation.link!)
                                    : SizedBox.shrink(),
                                (myLocation.notes != null &&
                                        myLocation.notes!.isNotEmpty)
                                    ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10),
                                        Text(
                                          "Notizen",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          myLocation.notes!,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    )
                                    : SizedBox.shrink(),
                              ],
                            ),
                        SizedBox(height: 30),
                        Text(
                          "Mit dir eingeteilte Dialoger*innen",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(color: Theme.of(context).primaryColor),
                        ref
                            .watch(
                              queryByIdsProvider(
                                QueryByIdsArgs(
                                  queryKey: "users",
                                  ids: assignments[myLocationId] as List,
                                ),
                              ),
                            )
                            .when(
                              data:
                                  (userDocs) => Column(
                                    children:
                                        userDocs.map((userDoc) {
                                          final userData = userDoc.data();
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 3,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${userData["first"] ?? ""} ${userData["last"] ?? ""}${userDoc.id == ref.watch(userProvider).value?.uid ? " (Du)" : ""}",
                                                ),
                                                Divider(),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              error: errorHandling,
                              loading: loadingHandling,
                            ),
                      ],
                    ),
                  );
                } else if (scheduleTimespan == Timespan.week ||
                    scheduleTimespan == Timespan.month) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children:
                          (scheduleTimespan == Timespan.week
                                  ? [1, 2, 3, 4, 5, 6, 7]
                                  : List<int>.generate(
                                    DateTime(
                                      scheduleStartDate.year,
                                      scheduleStartDate.month + 1,
                                      0,
                                    ).day,
                                    (i) => 1 + i,
                                  ))
                              .map((weekdayOrDayOfTheMonth) {
                                final date =
                                    scheduleTimespan == Timespan.week
                                        ? DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          scheduleStartDate.day -
                                              scheduleStartDate.weekday +
                                              weekdayOrDayOfTheMonth,
                                        )
                                        : DateTime(
                                          scheduleStartDate.year,
                                          scheduleStartDate.month,
                                          weekdayOrDayOfTheMonth,
                                        );
                                final dateFilteredScheduleDocs =
                                    scheduleDocs.docs.where((doc) {
                                      final scheduleDate =
                                          parseDateTimeFromTimestamp(
                                            doc.data()["date"],
                                          );
                                      return date.isSameDate(scheduleDate);
                                    }).toList();

                                return Card.outlined(
                                  color:
                                      date.isSameDate(DateTime.now())
                                          ? Theme.of(
                                            context,
                                          ).secondaryHeaderColor
                                          : null,
                                  child: Tappable(
                                    onTap: () {
                                      final currentTimespan = scheduleTimespan;
                                      final currentStartDate =
                                          scheduleStartDate;

                                      ref
                                          .read(
                                            scheduleTimespanProvider.notifier,
                                          )
                                          .state = Timespan.day;
                                      ref
                                          .read(
                                            scheduleStartDateProvider.notifier,
                                          )
                                          .state = date.getDayStart();
                                      context.push("./").then((_) {
                                        ref
                                            .read(
                                              scheduleTimespanProvider.notifier,
                                            )
                                            .state = currentTimespan;
                                        ref
                                            .read(
                                              scheduleStartDateProvider
                                                  .notifier,
                                            )
                                            .state = currentStartDate;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  date.getWeekdayAbbreviation(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  date.toFormattedDateString(),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 50,
                                              child: VerticalDivider(width: 20),
                                            ),
                                            () {
                                              if (dateFilteredScheduleDocs
                                                  .isEmpty) {
                                                return Center(
                                                  child: Text(
                                                    "Noch keine Einteilung erstellt",
                                                  ),
                                                );
                                              }
                                              final scheduleData =
                                                  dateFilteredScheduleDocs[0]
                                                      .data();
                                              final Map<String, dynamic>
                                              assignments =
                                                  scheduleData["personnel"] ??
                                                  {};

                                              final userId =
                                                  ref
                                                      .watch(userProvider)
                                                      .value
                                                      ?.uid;

                                              if (!flatten(
                                                assignments.values,
                                              ).contains(userId)) {
                                                return Center(
                                                  child: Text(
                                                    "An diesem Tag bist du nicht eingeteilt",
                                                  ),
                                                );
                                              }

                                              final String myLocationId =
                                                  assignments.entries
                                                      .where(
                                                        (entry) => (entry.value
                                                                as List)
                                                            .contains(userId),
                                                      )
                                                      .toList()[0]
                                                      .key;
                                              final filteredLocations =
                                                  locations
                                                      .where(
                                                        (doc) =>
                                                            doc.id ==
                                                            myLocationId,
                                                      )
                                                      .toList();
                                              if (filteredLocations.isEmpty) {
                                                return Center(
                                                  child: Text(
                                                    "Unbekannter Standplatz",
                                                  ),
                                                );
                                              }
                                              final myLocation =
                                                  filteredLocations[0];
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    myLocation.name,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                  ),

                                                  Text(
                                                    "${myLocation.street ?? "-"} ${myLocation.houseNumber ?? ""}, ${myLocation.postalCode ?? ""} ${myLocation.town ?? "-"}",
                                                  ),
                                                ],
                                              );
                                            }(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  );
                } else {
                  return Center();
                }
              },
              error: errorHandling,
              loading: loadingHandling,
            ),
          ),
        ],
      ),
    );
  }
}

class TimespanDateSwitcher extends ConsumerWidget {
  const TimespanDateSwitcher({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleTimespan = ref.watch(scheduleTimespanProvider);
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            if (scheduleTimespan == Timespan.day) {
              ref
                  .read(scheduleStartDateProvider.notifier)
                  .state = scheduleStartDate.subtract(Duration(days: 1));
            } else if (scheduleTimespan == Timespan.week) {
              ref.read(scheduleStartDateProvider.notifier).state = DateTime(
                scheduleStartDate.year,
                scheduleStartDate.month,
                scheduleStartDate.day - 7,
              );
            } else {
              ref.read(scheduleStartDateProvider.notifier).state = DateTime(
                scheduleStartDate.year,
                scheduleStartDate.month - 1,
              );
            }
          },
          icon: Icon(Icons.arrow_left, size: 30),
        ),
        Expanded(
          child: Center(
            child: Text(switch (scheduleTimespan) {
              Timespan.day =>
                "${scheduleStartDate.getWeekday()}, ${scheduleStartDate.toExtendedFormattedDateString()}${(scheduleStartDate.year != DateTime.now().year ? (" ${scheduleStartDate.year.toString()}") : "")}",
              Timespan.week => () {
                return "${scheduleStartDate.getWeekStart().toExtendedFormattedDateString()} - ${scheduleStartDate.getWeekStart().add(Duration(days: 6)).toExtendedFormattedDateString()}${scheduleStartDate.year != DateTime.now().year ? (" ${scheduleStartDate.year.toString()}") : ""}";
              }(),
              Timespan.month =>
                scheduleStartDate.getMonthName() +
                    (scheduleStartDate.year != DateTime.now().year
                        ? (" ${scheduleStartDate.year.toString()}")
                        : ""),
            }, style: TextStyle(fontSize: 20)),
          ),
        ),
        IconButton(
          onPressed: () {
            if (scheduleTimespan == Timespan.day) {
              ref
                  .read(scheduleStartDateProvider.notifier)
                  .state = scheduleStartDate.add(Duration(days: 1));
            } else if (scheduleTimespan == Timespan.week) {
              ref.read(scheduleStartDateProvider.notifier).state = DateTime(
                scheduleStartDate.year,
                scheduleStartDate.month,
                scheduleStartDate.day + 7,
              );
              print(
                ref.read(scheduleStartDateProvider).toFormattedDateTimeString(),
              );
            } else {
              ref.read(scheduleStartDateProvider.notifier).state = DateTime(
                scheduleStartDate.year,
                scheduleStartDate.month + 1,
              );
            }
          },
          icon: Icon(Icons.arrow_right, size: 30),
        ),
      ],
    );
  }
}
