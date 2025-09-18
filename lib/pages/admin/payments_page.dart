import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../basic_providers.dart';

final paymentsProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance
      .collection("payments")
      .where(
        "timestamp",
        isGreaterThan: Timestamp.fromDate(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ),
      )
      .orderBy("timestamp"),
);

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
        actions: [
          FilledButton.icon(
            onPressed: () {
              context.push("/admin/payment/new");
            },
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: Theme.of(context).primaryColor),
          Expanded(
            child: ListView(
              children:
                  paymentDocs.value!.docs.map((doc) {
                    final data = doc.data();
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
                                    "${data["first"] ?? ""} ${data["last"] ?? ""}",
                                  ),
                                ),
                                Expanded(
                                  child: Text(data["amount"].toString() ?? ""),
                                ),
                                IconButton(
                                  onPressed: () {
                                    context.push(
                                      "/admin/dialog/${doc.id ?? ""}",
                                    );
                                  },
                                  icon: Icon(Icons.edit),
                                  tooltip: "Bearbeiten",
                                ),
                                IconButton(
                                  onPressed: () {},
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
