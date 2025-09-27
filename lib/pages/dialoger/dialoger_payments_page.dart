import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/misc.dart';

import '../../app.dart';

final timespanProvider = StateProvider<String>((_) => "today");
final rangeProvider = StateProvider((_) {
  final yesterday = DateTime.now().subtract(Duration(days: 7));
  final tomorrow = DateTime.now().add(Duration(days: 1));
  return DateTimeRange(
    start: DateTime(yesterday.year, yesterday.month, yesterday.day),
    end: DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    ).subtract(Duration(milliseconds: 1)),
  );
});

final dialogerPaymentsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return FirebaseFirestore.instance
          .collection("payments")
          .where(
            Filter.and(
              switch (ref.watch(timespanProvider)) {
                "custom" => Filter.and(
                  Filter(
                    "timestamp",
                    isGreaterThanOrEqualTo: Timestamp.fromDate(
                      ref.watch(rangeProvider).start,
                    ),
                  ),
                  Filter(
                    "timestamp",
                    isLessThanOrEqualTo: Timestamp.fromDate(
                      ref.watch(rangeProvider).end,
                    ),
                  ),
                ),
                "all" => Filter(
                  "timestamp",
                  isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(0),
                ),
                "month" => Filter(
                  "timestamp",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(DateTime.now().year, DateTime.now().month, 0),
                  ),
                ),
                "week" => Filter(
                  "timestamp",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ).subtract(
                      Duration(days: DateTime.now().weekday - DateTime.monday),
                    ),
                  ),
                ),
                "yesterday" => () {
                  final yesterday = DateTime.now().subtract(Duration(days: 1));
                  return Filter.and(
                    Filter(
                      "timestamp",
                      isGreaterThanOrEqualTo: Timestamp.fromDate(
                        DateTime(
                          yesterday.year,
                          yesterday.month,
                          yesterday.day,
                        ),
                      ),
                    ),
                    Filter(
                      "timestamp",
                      isLessThan: Timestamp.fromDate(
                        DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        ),
                      ),
                    ),
                  );
                }(),
                "today" || _ => Filter(
                  "timestamp",
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  ),
                ),
              },
              Filter(
                "dialoger",
                isEqualTo: ref.watch(userProvider).value?.uid ?? "",
              ),
            ),
          )
          .orderBy("timestamp", descending: true)
          .snapshots();
    });

class DialogerPaymentsPage extends ConsumerStatefulWidget {
  const DialogerPaymentsPage({super.key});

  @override
  ConsumerState<DialogerPaymentsPage> createState() =>
      _DialogerPaymentsPageState();
}

class _DialogerPaymentsPageState extends ConsumerState<DialogerPaymentsPage> {
  @override
  Widget build(BuildContext context) {
    final paymentDocs = ref.watch(dialogerPaymentsProvider);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text("Leistungen"),
        actions: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 200),
            child: DropdownButtonFormField(
              value: ref.watch(timespanProvider),
              decoration: InputDecoration(
                hintText: "Zeitraum",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              items: [
                DropdownMenuItem(value: "today", child: Text("Heute")),
                DropdownMenuItem(value: "yesterday", child: Text("Gestern")),
                DropdownMenuItem(value: "week", child: Text("Diese Woche")),
                DropdownMenuItem(value: "month", child: Text("Dieser Monat")),
                DropdownMenuItem(value: "all", child: Text("Alle")),
                DropdownMenuItem(
                  value: "custom",
                  child: Text("Benutzerdefiniert"),
                ),
              ],
              onChanged: (newValue) async {
                if (newValue == "custom") {
                  final now = DateTime.now();
                  final DateTimeRange? range = await showDateRangePicker(
                    initialDateRange: ref.read(rangeProvider),
                    locale: Locale("de"),
                    context: context,
                    firstDate: DateTime(0),
                    lastDate: DateTime(now.year, now.month, now.day),
                  );
                  if (range != null) {
                    ref.read(rangeProvider.notifier).state = DateTimeRange(
                      start: range.start,
                      end: range.end.add(Duration(days: 1)),
                    );
                  }
                }
                ref.read(timespanProvider.notifier).state = newValue ?? "today";
              },
            ),
          ),
        ],
      ),
      body: paymentDocs.when(
        data:
            (data) => Column(
              children: [
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(flex: 2, child: Text("Datum")),
                    Expanded(flex: 2, child: Text("Betrag")),
                    Expanded(flex: 2, child: Text("Dein Anteil")),
                    Expanded(flex: 3, child: Text("Status")),

                    IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                    IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).canvasColor,
                      ),
                    ),
                  ],
                ),
                Divider(color: Theme.of(context).primaryColor),
                Expanded(
                  child: ListView(
                    children:
                        data.docs.map((doc) {
                          final data = doc.data();
                          final date =
                              ((data["timestamp"] ?? Timestamp.now())
                                      as Timestamp)
                                  .toDate();
                          late String datePrefix;
                          final today = DateTime.now();
                          final yesterday = DateTime.fromMicrosecondsSinceEpoch(
                            DateTime.now().millisecondsSinceEpoch -
                                1000 * 3600 * 24,
                          );
                          if (date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day) {
                            datePrefix = "Heute";
                          } else if (date.year == yesterday.year &&
                              date.month == yesterday.month &&
                              date.day == yesterday.day) {
                            datePrefix = "Gestern";
                          } else {
                            datePrefix =
                                "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.";
                          }
                          final isCoach =
                              ref
                                  .watch(userDataProvider)
                                  .value
                                  ?.data()?["role"] ==
                              "coach";
                          final num amount = data["amount"] as num;
                          late num dialogerShare;
                          if (data["type"] == "once") {
                            dialogerShare = (isCoach ? 0.35 : 0.333) * amount;
                          } else {
                            dialogerShare = (isCoach ? 0.6 : 0.5) * amount;
                          }
                          dialogerShare = ((dialogerShare * 100).round() / 100);
                          late Widget isPaidWidget;
                          if (data["type"] == "once" ||
                              data["has_first_payment"] == true ||
                              data["has_been_paid"] == "paid") {
                            isPaidWidget = getPill(
                              "Bezahlt",
                              Theme.of(context).primaryColor,
                              true,
                            );
                          } else if (data["has_been_paid"] == "pending") {
                            isPaidWidget = getPill(
                              "Ausstehend",
                              Theme.of(context).primaryColorLight,
                              false,
                            );
                          } else if (data["has_been_paid"] == "cancelled") {
                            isPaidWidget = getPill(
                              "Zurückgenommen",
                              Theme.of(context).cardColor,
                              false,
                            );
                          } else {
                            isPaidWidget = getPill(
                              "Keine Information",
                              Colors.grey,
                              true,
                            );
                          }
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          datePrefix,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${data["amount"].toStringAsFixed(2)}",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          dialogerShare.toStringAsFixed(2),
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(flex: 3, child: isPaidWidget),
                                      SizedBox(width: 5),
                                      IconButton(
                                        onPressed: () {
                                          context.push(
                                            "/dialoger/payment/${doc.id}/edit",
                                          );
                                        },
                                        icon: Icon(Icons.edit),
                                        tooltip: "Bearbeiten",
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: Text(
                                                    "Leistung löschen?",
                                                  ),
                                                  content: Text(
                                                    "Dieser Schritt kann nicht rückgängig gemacht werden",
                                                  ),
                                                  actions: [
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        context.pop();
                                                      },
                                                      child: Text("Abbrechen"),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              "payments",
                                                            )
                                                            .doc(doc.id)
                                                            .delete();
                                                        if (context.mounted) {
                                                          context.pop();
                                                          showSnackBar(
                                                            context,
                                                            "Leistung gelöscht!",
                                                          );
                                                        }
                                                      },
                                                      child: Text("Löschen"),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                        icon: Icon(Icons.delete),
                                        tooltip: "Löschen",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
        error: (object, stackTrace) {
          print(object);
          print(stackTrace);
          return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
        },
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
