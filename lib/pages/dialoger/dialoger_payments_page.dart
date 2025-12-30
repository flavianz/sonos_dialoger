import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/core/payment.dart';
import '../../components/payment_row.dart';
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
                    Expanded(child: Text("Datum")),
                    Expanded(child: Text("Betrag")),
                    Expanded(child: Text("Dein Anteil")),
                    Expanded(child: Text("Status")),
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
                        data.docs
                            .map(
                              (doc) => PaymentRow(
                                payment: Payment.fromDoc(doc),
                                isAdmin: false,
                              ),
                            )
                            .toList(),
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
