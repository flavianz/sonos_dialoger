import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';
import 'package:sonos_dialoger/core/payment.dart';
import 'package:sonos_dialoger/core/user.dart';

import '../providers/date_ranges.dart';

class PaymentsSummary extends ConsumerWidget {
  final Iterable<Payment> payments;
  final UserRole role;

  const PaymentsSummary({
    super.key,
    required this.payments,
    this.role = UserRole.admin,
  });

  @override
  Widget build(BuildContext context, ref) {
    final startDate = ref.watch(paymentsStartDateProvider);
    final timespan = ref.watch(paymentsTimespanProvider);

    final Widget sum = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );

    final afterDialogShare = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Nach DialogerInnen-Anteil", style: TextStyle(fontSize: 13)),
        Text(
          "${payments.sumWithoutDialogerShare.toStringAsFixed(2)} CHF",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );

    final dialogerShare = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );

    return Card.outlined(
      child: Container(
        padding: EdgeInsets.all(18),
        constraints:
            context.isScreenWide
                ? BoxConstraints(maxHeight: 300, minHeight: 0)
                : null,
        child:
            context.isScreenWide
                ? Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: sum),
                    Expanded(
                      child:
                          role == UserRole.admin
                              ? afterDialogShare
                              : dialogerShare,
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: sum),
                    Expanded(
                      child:
                          role == UserRole.admin
                              ? afterDialogShare
                              : dialogerShare,
                    ),
                  ],
                ),
      ),
    );
  }
}
