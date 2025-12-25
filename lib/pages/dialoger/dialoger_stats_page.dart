import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/app.dart';

import '../../components/payments_graph.dart';
import '../../components/timespan_dropdowns.dart';
import '../../core/payment.dart';
import '../../providers/date_ranges.dart';

final dialogerPaymentsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return FirebaseFirestore.instance
          .collection("payments")
          .where(
            Filter.and(
              ref.watch(paymentsDateFilterProvider),
              Filter(
                "dialoger",
                isEqualTo: ref.watch(userProvider).value?.uid ?? "",
              ),
            ),
          )
          .orderBy("timestamp", descending: true)
          .snapshots();
    });

class DialogerStatsPage extends ConsumerWidget {
  const DialogerStatsPage({super.key});

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

    final startDate = ref.watch(paymentsStartDateProvider);
    final timespan = ref.watch(paymentsTimespanProvider);

    final isScreenWide = MediaQuery.of(context).size.aspectRatio > 1;

    final payments =
        paymentDocs.value!.docs.map((doc) => Payment.fromDoc(doc)).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Statistiken")),
      body: ListView(
        children: [
          Card.outlined(child: PaymentsTimespanBar()),
          Card.outlined(child: PaymentsGraph(payments: payments)),
        ],
      ),
    );
  }
}
