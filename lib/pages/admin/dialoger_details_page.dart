import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/payment_row.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/components/payments_summary.dart';
import 'package:sonos_dialoger/core/payment.dart';
import 'package:sonos_dialoger/providers/firestore_providers/user_providers.dart';

import '../../components/misc.dart';
import '../../components/timespan_dropdowns.dart';
import '../../core/user.dart';
import '../../providers/firestore_providers.dart';

class DialogerDetailsPage extends ConsumerWidget {
  final String dialogerId;

  const DialogerDetailsPage({super.key, required this.dialogerId});

  @override
  Widget build(BuildContext context, ref) {
    final dialogerDoc = ref.watch(liveDialogerProvider(dialogerId));
    if (dialogerDoc.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (dialogerDoc.hasError) {
      print(dialogerDoc.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    final dialoger = dialogerDoc.value!;
    final dialogerPaymentDocs = ref.watch(localDialogerPaymentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text("${dialoger.first} ${dialoger.last}"),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                context.push("/admin/dialog/$dialogerId/edit");
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: "Leistungen", icon: Icon(Icons.request_page)),
              Tab(text: "Infos", icon: Icon(Icons.info_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            dialogerPaymentDocs.when(
              data: (paymentsData) {
                final payments = paymentsData.docs.map(
                  (doc) => Payment.fromDoc(doc),
                );

                final isScreenWide =
                    MediaQuery.of(context).size.aspectRatio > 1;

                final summaryCard = PaymentsSummary(payments: payments);
                final graph = Card.outlined(
                  child: PaymentsGraph(payments: payments.toList()),
                );

                return ListView(
                  children: [
                    Card.outlined(child: PaymentsTimespanBar()),
                    isScreenWide
                        ? Row(children: [summaryCard, Expanded(child: graph)])
                        : Column(children: [summaryCard, graph]),
                    Divider(height: 30, color: Theme.of(context).primaryColor),
                    Column(
                      children:
                          payments
                              .map(
                                (payment) =>
                                    PaymentRow(payment: payment, isAdmin: true),
                              )
                              .toList(),
                    ),
                  ],
                );
              },
              error: (object, stackTrace) {
                print(object);
                print(stackTrace);
                return Center(
                  child: Text("Ups, hier hat etwas nicht geklappt"),
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "${dialoger.last}, ${dialoger.first}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(switch (dialoger.role) {
                          UserRole.coach => "Coach",
                          UserRole.dialog => "DialogerIn",
                          UserRole.admin => "Admin",
                          null => "Noch keine Rolle",
                        }),
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 25,
                            minWidth: 25,
                          ),
                          decoration: BoxDecoration(
                            color:
                                dialoger.linked
                                    ? Colors.green.shade100
                                    : Colors.redAccent.shade100,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 10,
                              children: [
                                Icon(
                                  dialoger.linked ? Icons.check : Icons.close,
                                  size: 20,
                                  color:
                                      dialoger.linked
                                          ? Colors.green.shade900
                                          : Colors.red.shade900,
                                ),
                                Text(
                                  dialoger.linked
                                      ? "Account verknüpft"
                                      : "Nicht verknüpft",
                                  style: TextStyle(
                                    color:
                                        dialoger.linked
                                            ? Colors.green.shade900
                                            : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  !dialoger.linked
                      ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "Verknüpf-Code",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 12,
                                children: [
                                  Text(dialoger.id),
                                  IconButton(
                                    onPressed: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: dialoger.id),
                                      );
                                      if (context.mounted) {
                                        showSnackBar(
                                          context,
                                          "Verknüpf-Code kopiert!",
                                        );
                                      }
                                    },
                                    icon: Icon(
                                      Icons.copy,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
