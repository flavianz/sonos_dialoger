import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/core/payment.dart';
import 'package:sonos_dialoger/pages/admin/location_details_page.dart';
import 'package:sonos_dialoger/providers/date_ranges.dart';

import '../../components/misc.dart';
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

    final startDate = ref.watch(paymentsStartDateProvider);
    final timespan = ref.watch(paymentsTimespanProvider);

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final payments =
        paymentDocs.value!.docs.map((doc) => Payment.fromDoc(doc)).toList();

    final summaryCard = Card.outlined(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        constraints: BoxConstraints(maxHeight: 300),
        child: Column(
          mainAxisSize: isScreenWide ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment:
              isScreenWide
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.stretch,
          children: [
            Text(
              "Einnahmen ${switch (timespan) {
                Timespan.day => "${startDate.day}. ${startDate.getMonthName()}${startDate.year == DateTime.now().year ? "" : " ${startDate.year}"}",
                Timespan.week => "KW ${startDate.weekOfYear}",
                Timespan.month => "${startDate.getMonthName()}${startDate.year == DateTime.now().year ? "" : " ${startDate.year}"}",
              }}",
              style: TextStyle(fontSize: 13),
            ),
            Text(
              "${payments.sum.toStringAsFixed(2)} CHF",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              "+ -- % über dem Durchschnitt",
              style: TextStyle(fontSize: 13, color: Colors.green),
            ),
            SizedBox(height: 20),
            Text("Dein Anteil", style: TextStyle(fontSize: 13)),
            Text(
              "${payments.dialogerShareSum.toStringAsFixed(2)} CHF",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
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
