import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/core/payment.dart';

import '../../components/timespan_dropdowns.dart';
import '../../providers/firestore_providers.dart';

class DialogerPaymentsPage extends ConsumerStatefulWidget {
  const DialogerPaymentsPage({super.key});

  @override
  ConsumerState<DialogerPaymentsPage> createState() =>
      _DialogerPaymentsPageState();
}

class _DialogerPaymentsPageState extends ConsumerState<DialogerPaymentsPage> {
  @override
  Widget build(BuildContext context) {
    final paymentDocs = ref.watch(localDialogerPaymentsProvider);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text("Leistungen"),
        actions: [],
      ),
      body: paymentDocs.when(
        data:
            (data) => Column(
              children: [
                Card.outlined(child: PaymentsTimespanBar()),
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
                          final payment = Payment.fromDoc(doc);
                          final date = payment.timestamp;
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
                          late Widget isPaidWidget;
                          if (payment.getPaymentStatus() ==
                              PaymentStatus.paid) {
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
                                        flex: 2,
                                        child: Text(
                                          datePrefix,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          payment.amount.toStringAsFixed(2),
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          payment.amount.toStringAsFixed(2),
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
