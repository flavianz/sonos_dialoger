import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/payment_row.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/components/payments_summary.dart';
import 'package:sonos_dialoger/core/payment.dart';
import '../../components/timespan_dropdowns.dart';
import '../../providers/firestore_providers.dart';

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

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final payments =
        paymentDocs.value!.docs.map((doc) => Payment.fromDoc(doc)).toList();

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Leistungen"),
        actions: [],
      ),
      body: Column(
        children: [
          Card.outlined(child: PaymentsTimespanBar()),
          Divider(color: Theme.of(context).primaryColor),
          if (paymentDocs.value!.docs.isEmpty)
            Expanded(child: Center(child: Text("Keine Daten")))
          else
            Expanded(
              child: ListView(
                children: [
                  if (isScreenWide)
                    Row(
                      children: [
                        PaymentsSummary(payments: payments),
                        Expanded(
                          child: Card.outlined(
                            child: PaymentsGraph(payments: payments),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        PaymentsSummary(payments: payments),
                        Card.outlined(child: PaymentsGraph(payments: payments)),
                      ],
                    ),
                  Divider(color: Theme.of(context).primaryColor),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Text(
                      "Einzelne Leistungen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  ...paymentDocs.value!.docs.map(
                    (doc) => PaymentRow(
                      payment: Payment.fromDoc(doc),
                      isAdmin: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
