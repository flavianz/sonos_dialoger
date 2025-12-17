import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';

import '../core/payment.dart';
import '../providers/date_ranges.dart';

class PaymentsGraph extends ConsumerStatefulWidget {
  final List<Payment> payments;

  const PaymentsGraph({required this.payments, super.key});

  @override
  ConsumerState<PaymentsGraph> createState() => _PaymentsGraphState();
}

class _PaymentsGraphState extends ConsumerState<PaymentsGraph> {
  @override
  Widget build(BuildContext context) {
    BarChartGroupData generateGroupData(int millis, List<Payment> payments) {
      final onceTwint = payments
          .where(
            (payment) =>
                payment is OncePayment &&
                payment.paymentMethod == PaymentMethod.twint,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final onceSumup = payments
          .where(
            (payment) =>
                payment is OncePayment &&
                payment.paymentMethod == PaymentMethod.sumup,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final repeatingWithFirstPaymentTwint = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithFirstPayment &&
                payment.paymentMethod == PaymentMethod.twint,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final repeatingWithFirstPaymentSumup = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithFirstPayment &&
                payment.paymentMethod == PaymentMethod.sumup,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final repeatingWithoutFirstPayment = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithoutFirstPayment,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double borderRadius = 4;
      return BarChartGroupData(
        x: millis,
        groupVertically: true,
        barRods: [
          BarChartRodData(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
              topRight:
                  onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
            fromY: 0,
            toY: onceTwint.toDouble(),
            color: Colors.lightBlue.shade600,
            width: 15,
          ),
          BarChartRodData(
            fromY: onceTwint,
            toY: onceTwint + onceSumup,
            color: Colors.lightBlue.shade200,
            width: 15,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceTwint == 0 ? Radius.circular(borderRadius) : Radius.zero,
              bottomRight:
                  onceTwint == 0 ? Radius.circular(borderRadius) : Radius.zero,
              topRight:
                  repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
          ),
          BarChartRodData(
            fromY: onceTwint + onceSumup,
            toY: onceTwint + onceSumup + repeatingWithFirstPaymentTwint,
            color: Colors.lightGreen.shade800,
            width: 15,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceTwint + onceSumup == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceTwint + onceSumup == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topRight:
                  repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  repeatingWithFirstPaymentSumup +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
          ),
          BarChartRodData(
            fromY: onceTwint + onceSumup + repeatingWithFirstPaymentTwint,
            toY:
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentSumup,
            color: Colors.lightGreen.shade300,
            width: 15,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceTwint + onceSumup + repeatingWithFirstPaymentTwint == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceTwint + onceSumup + repeatingWithFirstPaymentTwint == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topRight:
                  repeatingWithoutFirstPayment == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  repeatingWithoutFirstPayment == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
          ),
          BarChartRodData(
            fromY:
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentSumup,
            toY:
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentSumup +
                repeatingWithoutFirstPayment,
            color: Colors.amberAccent.shade200,
            width: 15,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topRight: Radius.circular(borderRadius),
              topLeft: Radius.circular(borderRadius),
            ),
          ),
        ],
      );
    }

    Widget leftTitles(double value, TitleMeta meta) {
      if (value == meta.max) {
        return Container();
      }
      const style = TextStyle(fontSize: 10);
      return SideTitleWidget(
        meta: meta,
        child: Text(meta.formattedValue, style: style),
      );
    }

    final startDate = ref.watch(paymentsStartDateProvider);
    final timespan = ref.watch(paymentsTimespanProvider);
    final Map<int, List<Payment>> dateSortedData = {};
    double maxVal = 1;
    if (widget.payments.isNotEmpty) {
      final timespan = ref.watch(paymentsTimespanProvider);
      if (timespan == Timespan.day) {
        final hoursPrefixedPayments =
            widget.payments
                .map((payment) => (payment.timestamp.hour, payment))
                .toList();
        final int minHour =
            hoursPrefixedPayments.reduce((a, b) => a.$1 <= b.$1 ? a : b).$1;
        final int maxHour =
            hoursPrefixedPayments.reduce((a, b) => a.$1 >= b.$1 ? a : b).$1;
        for (int i = min(minHour, 8); i <= max(maxHour, 19); i++) {
          dateSortedData[i] =
              hoursPrefixedPayments
                  .where((payment) => payment.$1 == i)
                  .map((payment) => payment.$2)
                  .toList();
        }
      } else if (timespan == Timespan.week) {
        final weekdayPrefixedPayments =
            widget.payments
                .map((payment) => (payment.timestamp.weekday, payment))
                .toList();
        for (int i = 1; i <= 7; i++) {
          dateSortedData[i] =
              weekdayPrefixedPayments
                  .where((payment) => payment.$1 == i)
                  .map((payment) => payment.$2)
                  .toList();
        }
      } else if (timespan == Timespan.month) {
        final dayPrefixedPayments =
            widget.payments
                .map((payment) => (payment.timestamp.day, payment))
                .toList();
        for (int i = 1; i <= startDate.getMonthDayCount(); i++) {
          dateSortedData[i] =
              dayPrefixedPayments
                  .where((payment) => payment.$1 == i)
                  .map((payment) => payment.$2)
                  .toList();
        }
      }

      if (dateSortedData.isNotEmpty) {
        maxVal = max(
          dateSortedData.values
              .map(
                (list) =>
                    list.fold(0.0, (total, payment) => total + payment.amount),
              )
              .reduce(max),
          1,
        );
      }
    }
    final sortedDates =
        dateSortedData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: EdgeInsets.all(18),
      constraints: BoxConstraints(maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                widget.payments.isEmpty
                    ? Center(child: Text("Keine Daten"))
                    : BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              interval: max(maxVal / 6 - (maxVal / 6) % 1, 1),
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: leftTitles,
                            ),
                          ),
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (titleData, _) {
                                return switch (ref.watch(
                                  paymentsTimespanProvider,
                                )) {
                                  Timespan.day => Text(
                                    titleData.toString().padLeft(2, "0"),
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Timespan.week => Text(switch (titleData) {
                                    2 => "Di",
                                    3 => "Mi",
                                    4 => "Do",
                                    5 => "Fr",
                                    6 => "Sa",
                                    7 => "So",
                                    1 || _ => "Mo",
                                  }),
                                  Timespan.month =>
                                    titleData % 2 == 1
                                        ? Text(
                                          "${titleData.toString().padLeft(2, "0")}.",
                                          style: TextStyle(fontSize: 13),
                                        )
                                        : SizedBox.shrink(),
                                };
                              },
                              reservedSize: 20,
                            ),
                          ),
                        ),
                        barGroups:
                            sortedDates
                                .map(
                                  (entry) =>
                                      generateGroupData(entry.key, entry.value),
                                )
                                .toList(),
                        gridData: FlGridData(
                          horizontalInterval: max(
                            maxVal / 6 - (maxVal / 6) % 1,
                            1,
                          ),
                          show: true,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              ),
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
          ),
          SizedBox(height: 10),
          widget.payments.isNotEmpty
              ? Row(
                spacing: 10,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    spacing: 3,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.amberAccent,
                        ),
                        height: 12,
                        width: 12,
                      ),
                      Tooltip(
                        message: "LSV ohne Erstzahlung",
                        child: Text("LSV", style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 3,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.lightGreen.shade300,
                            ),
                            height: 12,
                            width: 12,
                          ),
                          Tooltip(
                            message: "LSV mit Erstzahlung via SumUp",
                            child: Text(
                              "LSV mit SumUp",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 3,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.lightGreen.shade800,
                            ),
                            height: 12,
                            width: 12,
                          ),
                          Tooltip(
                            message: "LSV mit Erstzahlung via Twint",
                            child: Text(
                              "LSV mit Twint",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 3,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.lightBlue.shade200,
                            ),
                            height: 12,
                            width: 12,
                          ),
                          Tooltip(
                            message: "Einmalige Zahlung via SumUp",
                            child: Text(
                              "Einmalig mit SumUp",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 3,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.lightBlue.shade700,
                            ),
                            height: 12,
                            width: 12,
                          ),
                          Tooltip(
                            message: "Einmalige Zahlung via Twint",
                            child: Text(
                              "Einmalig mit Twint",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
