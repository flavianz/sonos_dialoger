import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/components/payment_row.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/components/payments_summary.dart';
import 'package:sonos_dialoger/core/payment.dart';
import '../../components/timespan_dropdowns.dart';
import '../../providers/basic_providers.dart';
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
        actions: [
          FilledButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => PaymentsExportDialog(),
              );
            },
            icon: Icon(Icons.drive_folder_upload),
            label: Text("Export"),
          ),
        ],
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

class PaymentsExportDialog extends ConsumerStatefulWidget {
  const PaymentsExportDialog({super.key});

  @override
  ConsumerState<PaymentsExportDialog> createState() =>
      _PaymentsExportDialogState();
}

class _PaymentsExportDialogState extends ConsumerState<PaymentsExportDialog> {
  bool loading = false;
  DateTimeRange? range;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Leistungen exportieren"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              range?.start.toExtendedFormattedDateString() ?? "-",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text("bis"),
            Text(
              range?.end.toExtendedFormattedDateString() ?? "-",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () async {
                final newRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2200),
                );
                if (newRange != null) {
                  setState(() {
                    range = newRange;
                  });
                }
              },
              child: Text("Zeitraum wählen"),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            context.pop();
          },
          child: Text("Abbrechen"),
        ),
        FilledButton(
          onPressed:
              range == null
                  ? null
                  : () async {
                    setState(() {
                      loading = true;
                    });
                    final result = await ref.read(
                      callableProvider(
                        CallableProviderArgs("exportPayments", {
                          "start": range!.start.toIso8601String(),
                          "end": range!.end.toIso8601String(),
                        }),
                      ).future,
                    );
                    setState(() {
                      loading = false;
                    });
                    print("result ${result.data}");
                    if (context.mounted) {
                      if (result.data == true) {
                        context.pop();
                        showSnackBar(context, "Export-Email verschickt!");
                      } else {
                        showSnackBar(context, "Export fehlgeschlagen!");
                      }
                    }
                  },
          child:
              loading
                  ? SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : Text("Exportieren"),
        ),
      ],
    );
  }
}
