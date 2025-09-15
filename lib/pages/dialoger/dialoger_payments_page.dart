import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/misc.dart';

import '../../app.dart';

final dialogerPaymentsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      print(ref.watch(userProvider).value?.uid ?? "");
      return FirebaseFirestore.instance
          .collection("payments")
          .where(
            Filter.and(
              Filter(
                "timestamp",
                isGreaterThan: Timestamp.fromDate(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                ),
              ),
              Filter(
                "dialoger",
                isEqualTo: ref.watch(userProvider).value?.uid ?? "",
              ),
            ),
          )
          .orderBy("timestamp")
          .snapshots();
    });

class DialogerPaymentsPage extends ConsumerWidget {
  const DialogerPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final paymentDocs = ref.watch(dialogerPaymentsProvider);

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
        actions: [
          FilledButton.icon(
            onPressed: () {
              context.push("/admin/payment/new");
            },
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
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
                          "${date.day.toString().padLeft(2, '0')}. ${date.month.toString().padLeft(2, '0')}.";
                    }
                    final isCoach =
                        ref.watch(userDataProvider).value?.data()?["role"] ==
                        "coach";
                    final double amount = data["amount"] as double;
                    late double dialogerShare;
                    if (data["type"] == "once") {
                      dialogerShare = (isCoach ? 0.35 : 0.333) * amount;
                    } else {
                      dialogerShare = (isCoach ? 0.6 : 0.5) * amount;
                    }
                    late Widget isPaidWidget;
                    if (data["type"] == "once" ||
                        data["has_first_payment"] == true ||
                        data["has_been_paid"] == "paid") {
                      isPaidWidget = getPill("Bezahlt", Colors.green, true);
                    } else if (data["has_been_paid"] == "pending") {
                      isPaidWidget = getPill("Ausstehend", Colors.amber, true);
                    } else if (data["has_been_paid"] == "cancelled") {
                      isPaidWidget = getPill(
                        "Zurückgenommen",
                        Colors.red,
                        true,
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
                                  flex: 3,
                                  child: Text(
                                    "$datePrefix, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "${data["amount"].toString()} CHF",
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text("$dialogerShare CHF"),
                                ),
                                Expanded(flex: 2, child: isPaidWidget),
                                SizedBox(width: 5),
                                IconButton(
                                  onPressed: () {
                                    context.push("/admin/dialog/${doc.id}");
                                  },
                                  icon: Icon(Icons.edit),
                                  tooltip: "Bearbeiten",
                                ),
                                IconButton(
                                  onPressed: () {},
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
