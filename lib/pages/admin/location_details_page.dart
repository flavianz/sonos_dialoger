import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/clickable_link.dart';
import 'package:sonos_dialoger/components/payment_row.dart';
import 'package:sonos_dialoger/components/payments_graph.dart';
import 'package:sonos_dialoger/components/payments_summary.dart';
import 'package:sonos_dialoger/core/payment.dart';

import '../../components/timespan_dropdowns.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/firestore_providers/location_providers.dart';

class LocationDetailsPage extends ConsumerWidget {
  final String locationId;

  const LocationDetailsPage({super.key, required this.locationId});

  @override
  Widget build(BuildContext context, ref) {
    final locationDoc = ref.watch(locationProvider(locationId));
    if (locationDoc.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (locationDoc.hasError) {
      print(locationDoc.error);
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }
    final location = locationDoc.value!;
    final locationPaymentDocs = ref.watch(locationPaymentsProvider(locationId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(location.name),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                context.push("/admin/location/$locationId/edit");
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
            locationPaymentDocs.when(
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
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Preis",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Text("${location.price} CHF pro Tag"),
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Kontakt",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  location.link != null
                      ? ClickableLink(link: location.link!)
                      : Text("Kein Link"),
                  location.email != null
                      ? ClickableLink(
                        link: "mailto:${location.email!}",
                        label: location.email!,
                      )
                      : Text("Keine Email"),
                  location.phone != null
                      ? ClickableLink(
                        link: "tel:${location.phone!}",
                        label: location.phone,
                      )
                      : Text("Keine Telefonnummer"),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Adresse",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Text(
                    "${location.street ?? "-"} ${location.houseNumber ?? ""}",
                  ),
                  Text("${location.postalCode ?? ""} ${location.town ?? "-"}"),
                  Padding(
                    padding: EdgeInsets.only(left: 4, top: 12),
                    child: Text(
                      "Notizen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Divider(),
                  Text(
                    (location.notes == null || location.notes!.isEmpty)
                        ? "Keine Notizen"
                        : location.notes!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
