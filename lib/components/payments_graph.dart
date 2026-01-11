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
    BarChartGroupData generateGroupData(
      int millis,
      List<Payment> payments,
      double width,
    ) {
      final double onceTwint = payments
          .where(
            (payment) =>
                payment is OncePayment &&
                payment.paymentMethod == PaymentMethod.twint,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double onceSumup = payments
          .where(
            (payment) =>
                payment is OncePayment &&
                payment.paymentMethod == PaymentMethod.sumup,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double onceCash = payments
          .where(
            (payment) =>
                payment is OncePayment &&
                payment.paymentMethod == PaymentMethod.cash,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double repeatingWithFirstPaymentTwint = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithFirstPayment &&
                payment.paymentMethod == PaymentMethod.twint,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double repeatingWithFirstPaymentSumup = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithFirstPayment &&
                payment.paymentMethod == PaymentMethod.sumup,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double repeatingWithFirstPaymentCash = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithFirstPayment &&
                payment.paymentMethod == PaymentMethod.cash,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double repeatingWithoutFirstPayment = payments
          .where(
            (payment) =>
                payment is RepeatingPayment &&
                payment is RepeatingPaymentWithoutFirstPayment,
          )
          .fold(0.0, (total, payment) => total + payment.amount);
      final double borderRadius = width / 4;

      return BarChartGroupData(
        x: millis,
        groupVertically: true,
        barRods: [
          BarChartRodData(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
              topRight:
                  onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
            fromY: 0,
            toY: onceCash.toDouble(),
            color: Colors.lightBlue.shade800,
            width: width,
          ),
          BarChartRodData(
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash == 0 ? Radius.circular(borderRadius) : Radius.zero,
              bottomRight:
                  onceCash == 0 ? Radius.circular(borderRadius) : Radius.zero,
              topRight:
                  onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
            fromY: onceCash,
            toY: onceCash + onceTwint,
            color: Colors.lightBlue.shade600,
            width: width,
          ),
          BarChartRodData(
            fromY: onceCash + onceTwint,
            toY: onceCash + onceTwint + onceSumup,
            color: Colors.lightBlue.shade200,
            width: width,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash + onceTwint == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceCash + onceTwint == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topRight:
                  repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
          ),
          BarChartRodData(
            fromY: onceCash + onceTwint + onceSumup,
            toY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentCash,
            color: Colors.lightGreen.shade800,
            width: width,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash + onceTwint + onceSumup == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceCash + onceTwint + onceSumup == 0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topRight:
                  repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              topLeft:
                  repeatingWithFirstPaymentSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithoutFirstPayment ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
            ),
          ),
          BarChartRodData(
            fromY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentCash,
            toY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentCash +
                repeatingWithFirstPaymentTwint,
            color: Colors.lightGreen.shade600,
            width: width,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentCash ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentCash ==
                          0
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
            fromY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentCash +
                repeatingWithFirstPaymentTwint,
            toY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentCash +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentSumup,
            color: Colors.lightGreen.shade300,
            width: width,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithFirstPaymentTwint ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentCash +
                              repeatingWithFirstPaymentTwint ==
                          0
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
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentCash +
                repeatingWithFirstPaymentSumup,
            toY:
                onceCash +
                onceTwint +
                onceSumup +
                repeatingWithFirstPaymentTwint +
                repeatingWithFirstPaymentCash +
                repeatingWithFirstPaymentSumup +
                repeatingWithoutFirstPayment,
            color: Colors.amberAccent.shade200,
            width: width,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentCash +
                              repeatingWithFirstPaymentSumup ==
                          0
                      ? Radius.circular(borderRadius)
                      : Radius.zero,
              bottomRight:
                  onceCash +
                              onceTwint +
                              onceSumup +
                              repeatingWithFirstPaymentTwint +
                              repeatingWithFirstPaymentCash +
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

    return LayoutBuilder(
      builder: (context, constraints) {
        late final int columnLabelInterval;
        if (constraints.maxWidth < 600) {
          columnLabelInterval = 3;
        } else if (constraints.maxWidth < 900) {
          columnLabelInterval = 2;
        } else {
          columnLabelInterval = 1;
        }

        final timespan = ref.watch(paymentsTimespanProvider);

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
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (
                                  BarChartGroupData group,
                                  int groupIndex,
                                  BarChartRodData rod,
                                  int rodIndex,
                                ) {
                                  final double ownValue = rod.toY - rod.fromY;

                                  if (ownValue <= 0) return null;

                                  return BarTooltipItem(
                                    ownValue.toStringAsFixed(2),
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  interval: max(
                                    maxVal / 6 - (maxVal / 6) % 1,
                                    1,
                                  ),
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
                                    return switch (timespan) {
                                      Timespan.day =>
                                        titleData % columnLabelInterval == 0
                                            ? Text(
                                              "${titleData.toInt().toString().padLeft(2, "0")}h",
                                              style: TextStyle(fontSize: 13),
                                            )
                                            : SizedBox.shrink(),
                                      Timespan.week => Text(switch (titleData) {
                                        2 => "Di",
                                        3 => "Mi",
                                        4 => "Do",
                                        5 => "Fr",
                                        6 => "Sa",
                                        7 => "So",
                                        1 || _ => "Mo",
                                      }, style: TextStyle(fontSize: 13)),
                                      Timespan.month =>
                                        titleData % columnLabelInterval == 0
                                            ? Text(
                                              "${titleData.toInt().toString().padLeft(2, "0")}.",
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
                                      (entry) => generateGroupData(
                                        entry.key,
                                        entry.value,
                                        (constraints.maxWidth - 20) /
                                                (switch (timespan) {
                                                  Timespan.day => 20,
                                                  Timespan.week => 20,
                                                  Timespan.month => 31,
                                                }) -
                                            3,
                                      ),
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
                                  color: Colors.lightGreen.shade200,
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
                                  color: Colors.lightGreen.shade500,
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
                                message: "LSV mit Erstzahlung in Bar",
                                child: Text(
                                  "LSV in Bar",
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
                                  color: Colors.lightBlue.shade100,
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
                                  color: Colors.lightBlue.shade400,
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
                          Row(
                            spacing: 3,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: Colors.lightBlue.shade800,
                                ),
                                height: 12,
                                width: 12,
                              ),
                              Tooltip(
                                message: "Einmalige Zahlung in Bar",
                                child: Text(
                                  "Einmalig in Bar",
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
      },
    );
  }
}
