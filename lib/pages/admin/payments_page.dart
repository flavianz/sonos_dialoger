import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/core/payment.dart';
import 'package:sonos_dialoger/providers/date_ranges.dart';

import '../../components/misc.dart';

final paymentsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection("payments")
      .where(paymentsDateFilterProvider)
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
        actions: [],
      ),
      body: Column(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Expanded(
            child: ListView(
              children:
                  paymentDocs.value!.docs.map((doc) {
                    final payment = Payment.fromDoc(doc);
                    late String datePrefix;
                    final today = DateTime.now();
                    final yesterday = DateTime.fromMicrosecondsSinceEpoch(
                      DateTime.now().millisecondsSinceEpoch - 1000 * 3600 * 24,
                    );
                    if (payment.timestamp.year == today.year &&
                        payment.timestamp.month == today.month &&
                        payment.timestamp.day == today.day) {
                      datePrefix = "Heute";
                    } else if (payment.timestamp.year == yesterday.year &&
                        payment.timestamp.month == yesterday.month &&
                        payment.timestamp.day == yesterday.day) {
                      datePrefix = "Gestern";
                    } else {
                      datePrefix =
                          "${payment.timestamp.day.toString().padLeft(2, '0')}.${payment.timestamp.month.toString().padLeft(2, '0')}.";
                    }
                    late Widget isPaidWidget;
                    if (payment.getPaymentStatus() == PaymentStatus.paid) {
                      isPaidWidget = getPill(
                        "Bezahlt",
                        Theme.of(context).primaryColor,
                        true,
                      );
                    } else if (payment.getPaymentStatus() ==
                        PaymentStatus.pending) {
                      isPaidWidget = getPill(
                        "Ausstehend",
                        Theme.of(context).primaryColorLight,
                        false,
                      );
                    } else if (payment.getPaymentStatus() ==
                        PaymentStatus.cancelled) {
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
                                    "${payment.amount.toString()} CHF",
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
