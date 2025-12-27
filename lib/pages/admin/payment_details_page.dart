import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sonos_dialoger/components/misc.dart';

import '../../core/payment.dart';
import '../../providers/firestore_providers.dart';
import '../../providers/firestore_providers/location_providers.dart';
import '../../providers/firestore_providers/user_providers.dart';

class PaymentDetailsPage extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailsPage({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context, ref) {
    final paymentDoc = ref.watch(paymentProvider(paymentId));
    final locationDoc = ref.watch(paymentLocationProvider(paymentId));
    final dialogerDoc = ref.watch(paymentDialogerProvider(paymentId));

    if (paymentDoc.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Laden...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (paymentDoc.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text("Fehler")),
        body: Center(child: Text("Ups, hier hat etwas nicht geklappt")),
      );
    }

    final payment = Payment.fromDoc(paymentDoc.value!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Leistung vom ${payment.timestamp.toFormattedDateString()}",
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              context.push("/dialoger/payment/${payment.id}/edit");
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Card.outlined(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceEvenly,
                runAlignment: WrapAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text("Betrag"),
                      Text(
                        "${payment.amount.toStringAsFixed(2)} CHF",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Dialoger*innen-Anteil"),
                      Text(
                        "${(payment.dialogerShare * 100).toStringAsFixed(2)} %",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Betrag nach Dialoger*innen-Anteil"),
                      Text(
                        "${(payment.amount - payment.dialogerShare * payment.amount).toStringAsFixed(2)} CHF",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Name Spender*in"),
                Text(
                  payment is OncePayment
                      ? (payment) {
                        final oncePayment = payment as OncePayment;
                        if ((oncePayment.first == null ||
                                oncePayment.first!.isEmpty) &&
                            (oncePayment.last == null ||
                                oncePayment.last!.isEmpty)) {
                          return "-";
                        }
                        return "${oncePayment.first} ${oncePayment.last}";
                      }(payment)
                      : (payment) {
                        final repeatingPayment = payment as RepeatingPayment;
                        return "${repeatingPayment.first} ${repeatingPayment.last}";
                      }(payment),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Zahlungsrhytmus"),
                Text(
                  payment.isOncePayment()
                      ? "Einmalig"
                      : switch ((payment as RepeatingPayment).paymentInterval) {
                        PaymentInterval.monthly => "Monatlich",
                        PaymentInterval.quarterly => "Vierteljährlich",
                        PaymentInterval.semester => "Halbjährlich",
                        PaymentInterval.yearly => "Jährlich",
                      },
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.isOncePayment()
                      ? "Zahlungsmittel"
                      : "Erstzahlungsmittel",
                ),
                Text(
                  payment.isOncePayment()
                      ? (payment as OncePayment).paymentMethod
                          .paymentMethodName()
                      : (payment is RepeatingPaymentWithoutFirstPayment)
                      ? "Ohne Erstzahlung"
                      : (payment as RepeatingPaymentWithFirstPayment)
                          .paymentMethod
                          .paymentMethodName(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Zahlungsstatus"),
                payment.getPaymentStatus().widget(context),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Standplatz"),
                locationDoc.when(
                  data:
                      (location) => Text(
                        "${location.name}, ${location.town ?? "-"}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  error: errorHandling,
                  loading: loadingHandling,
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dailoger*in"),
                dialogerDoc.when(
                  data:
                      (dialoguer) => Text(
                        "${dialoguer.first} ${dialoguer.last}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  error: errorHandling,
                  loading: loadingHandling,
                ),
              ],
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}
