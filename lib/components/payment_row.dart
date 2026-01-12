import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/core/payment.dart';

import 'misc.dart';

class PaymentRow extends StatelessWidget {
  final Payment payment;
  final bool isAdmin;

  const PaymentRow({super.key, required this.payment, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
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
      isPaidWidget = getPill("Bezahlt", Theme.of(context).primaryColor, true);
    } else if (payment.getPaymentStatus() == PaymentStatus.pending) {
      isPaidWidget = getPill(
        "Ausstehend",
        Theme.of(context).primaryColorLight,
        false,
      );
    } else if (payment.getPaymentStatus() == PaymentStatus.cancelled) {
      isPaidWidget = getPill(
        "Zurückgenommen",
        Theme.of(context).cardColor,
        false,
      );
    } else {
      isPaidWidget = getPill("Keine Information", Colors.grey, true);
    }

    return Column(
      children: [
        Tappable(
          onTap:
              isAdmin
                  ? () {
                    context.push("/admin/payment/${payment.id}");
                  }
                  : null,
          child: Row(
            children: [
              Expanded(child: Text(datePrefix, style: TextStyle(fontSize: 15))),
              if (isAdmin)
                Expanded(
                  child: Text((payment) {
                    if (payment is OncePayment) {
                      if (payment.last != null && payment.last!.isNotEmpty) {
                        return payment.last!;
                      } else {
                        return "-";
                      }
                    } else {
                      final repeatingPayment = payment as RepeatingPayment;
                      return repeatingPayment.last;
                    }
                  }(payment), style: TextStyle(fontSize: 15)),
                )
              else
                SizedBox.shrink(),
              Expanded(
                child: Text(
                  "${payment.amount.toString()} CHF",
                  style: TextStyle(fontSize: 15),
                ),
              ),
              if (!isAdmin)
                Expanded(
                  child: Text(
                    (payment.amount * payment.dialogerShare).toStringAsFixed(2),
                    style: TextStyle(fontSize: 15),
                  ),
                )
              else
                SizedBox.shrink(),
              Expanded(child: isPaidWidget),
              IconButton(
                onPressed:
                    isAdmin || payment.canDialogerStillEdit()
                        ? () {
                          context.push("/dialoger/payment/${payment.id}/edit");
                        }
                        : null,
                icon: Icon(Icons.edit),
                tooltip: "Bearbeiten",
              ),
              IconButton(
                onPressed:
                    isAdmin || payment.canDialogerStillEdit()
                        ? () {
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
                                        await FirebaseFirestore.instance
                                            .collection("payments")
                                            .doc(payment.id)
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
                        }
                        : null,
                icon: Icon(Icons.delete),
                tooltip: "Löschen",
              ),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}
