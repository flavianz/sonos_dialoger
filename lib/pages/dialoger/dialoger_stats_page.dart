import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/core/payment.dart';
import 'package:sonos_dialoger/core/user.dart';
import '../../components/payments_summary.dart';
import '../../components/timespan_dropdowns.dart';
import '../../providers/firestore_providers.dart';

class DialogerStatsPage extends ConsumerWidget {
  const DialogerStatsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final paymentDocs = ref.watch(localDialogerPaymentsProvider);

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

    final summaryCard = PaymentsSummary(
      payments: payments,
      role: UserRole.dialog,
    );

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text("Statistiken"),
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
                        summaryCard,
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
                        summaryCard,
                        Card.outlined(child: PaymentsGraph(payments: payments)),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
