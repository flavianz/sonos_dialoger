import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/input_box.dart';

import '../../components/misc.dart';
import '../../providers.dart';

final paymentsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection("payments")
      .where(switch (ref.watch(timespanProvider)) {
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
                DateTime(yesterday.year, yesterday.month, yesterday.day),
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
      })
      .orderBy("timestamp", descending: true)
      .snapshots();
});

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final paymentDocs = ref.watch(paymentsProvider);

    if (paymentDocs.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (paymentDocs.hasError) {
      print(paymentDocs.error);
      return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
    }

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Leistungen"),
        actions: [DateRangeDropdown()],
      ),
      body: Column(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Expanded(
            child: ListView(
              children:
                  paymentDocs.value!.docs.map((doc) {
                    final data = doc.data();
                    final date =
                        ((data["timestamp"] ?? Timestamp.now()) as Timestamp)
                            .toDate();
                    late String datePrefix;
                    final today = DateTime.now();
                    final yesterday = DateTime.fromMicrosecondsSinceEpoch(
                      DateTime.now().millisecondsSinceEpoch - 1000 * 3600 * 24,
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
                    late Widget isPaidWidget;
                    if (data["type"] == "once" ||
                        data["has_first_payment"] == true ||
                        data["payment_status"] == "paid") {
                      isPaidWidget = getPill(
                        "Bezahlt",
                        Theme.of(context).primaryColor,
                        true,
                      );
                    } else if (data["payment_status"] == "pending") {
                      isPaidWidget = getPill(
                        "Ausstehend",
                        Theme.of(context).primaryColorLight,
                        false,
                      );
                    } else if (data["payment_status"] == "cancelled") {
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
                                  child: Text(
                                    datePrefix,
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "${data["amount"].toString()} CHF",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                                Expanded(child: isPaidWidget),
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
                                            title: Text("Leistung löschen?"),
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
                                                      .collection("payments")
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
    );
  }
}
