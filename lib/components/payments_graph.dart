/*import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/pages/admin/location_details_page.dart';

import '../core/payment.dart';
import '../providers.dart';

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
      return BarChartGroupData(
        x: millis,
        groupVertically: true,
        barRods: [
          BarChartRodData(
            fromY: 0,
            toY: onceTwint.toDouble(),
            color: Colors.lightBlue.shade600,
            width: 15,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            fromY: onceTwint,
            toY: onceTwint + onceSumup,
            color: Colors.lightBlue.shade200,
            width: 15,
            borderRadius: BorderRadius.zero,
          ),
          BarChartRodData(
            fromY: onceTwint + onceSumup,
            toY: onceTwint + onceSumup + repeatingWithFirstPaymentTwint,
            color: Colors.lightGreen.shade800,
            width: 15,
            borderRadius: BorderRadius.zero,
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
            borderRadius: BorderRadius.zero,
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
            borderRadius: BorderRadius.zero,
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

    return Card.outlined(
      child: Container(
        padding: EdgeInsets.all(18),
        constraints: BoxConstraints(maxHeight: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    final currentRange = ref.read(rangeProvider);
                    final timespan = ref.read(paymentsTimespanProvider);
                    if (timespan == Timespan.today ||
                        timespan == Timespan.yesterday ||
                        timespan == Timespan.week) {
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: currentRange.start.subtract(
                          Duration(days: timespan == Timespan.week ? 7 : 1),
                        ),
                        end: currentRange.end.subtract(
                          Duration(days: timespan == Timespan.week ? 7 : 1),
                        ),
                      );
                      ref.read(paymentsTimespanProvider.notifier).state =
                          Timespan.custom;
                    } else if (timespan == Timespan.month) {
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: DateTime(
                          currentRange.start.year,
                          currentRange.start.month - 1,
                        ),
                        end: DateTime(
                          currentRange.end.year,
                          currentRange.end.month - 1,
                        ),
                      );
                      ref.read(paymentsTimespanProvider.notifier).state =
                          Timespan.custom;
                    } else if (timespan == Timespan.custom) {
                      final diff = currentRange.end.difference(
                        currentRange.start,
                      );
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: currentRange.start.subtract(diff),
                        end: currentRange.end.subtract(diff),
                      );
                    }
                  },
                  icon: Icon(Icons.arrow_left),
                ),
                Text(switch (ref.watch(paymentsTimespanProvider)) {
                  Timespan.today => "Heute",
                  Timespan.yesterday => "Gestern",
                  Timespan.week => "Diese Woche",
                  Timespan.month => "Dieser Monat",
                  Timespan.custom => () {
                    final dateRange = ref.watch(rangeProvider);
                    return "${dateRange.start.day}.${dateRange.start.month}. - ${dateRange.end.day}.${dateRange.end.month}.";
                  }(),
                }, style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () {
                    final currentRange = ref.read(rangeProvider);
                    final timespan = ref.read(paymentsTimespanProvider);
                    if (timespan == Timespan.today ||
                        timespan == Timespan.yesterday ||
                        timespan == Timespan.week) {
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: currentRange.start.add(
                          Duration(days: timespan == Timespan.week ? 7 : 1),
                        ),
                        end: currentRange.end.add(
                          Duration(days: timespan == Timespan.week ? 7 : 1),
                        ),
                      );
                      ref.read(paymentsTimespanProvider.notifier).state =
                          Timespan.custom;
                    } else if (timespan == Timespan.month) {
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: DateTime(
                          currentRange.start.year,
                          currentRange.start.month + 1,
                        ),
                        end: DateTime(
                          currentRange.end.year,
                          currentRange.end.month + 1,
                        ),
                      );
                      ref.read(paymentsTimespanProvider.notifier).state =
                          Timespan.custom;
                    } else if (timespan == Timespan.custom) {
                      final diff = currentRange.end.difference(
                        currentRange.start,
                      );
                      ref.read(rangeProvider.notifier).state = DateTimeRange(
                        start: currentRange.start.add(diff),
                        end: currentRange.end.add(diff),
                      );
                    }
                  },
                  icon: Icon(Icons.arrow_right),
                ),
              ],
            ),
            SizedBox(height: 5),
            Expanded(
              child:
                  widget.payments.isEmpty
                      ? Center(child: Text("Keine Daten"))
                      : BarChart(
                        BarChartData(
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                interval: max(
                                  ((maxVal / 6) - ((maxVal / 6) % 10))
                                          .toDouble() *
                                      2,
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
                                  return switch (ref.watch(
                                    paymentsTimespanProvider,
                                  )) {
                                    Timespan.today ||
                                    Timespan.yesterday => Text(
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
                                      titleData %
                                                  (DateTime.now().day / 8)
                                                      .ceil() ==
                                              0
                                          ? Text(
                                            "${titleData.toString().padLeft(2, "0")}.",
                                            style: TextStyle(fontSize: 13),
                                          )
                                          : SizedBox.shrink(),
                                    Timespan.custom => () {
                                      final dateRange = ref.watch(
                                        rangeProvider,
                                      );
                                      final duration =
                                          dateRange.end
                                              .difference(dateRange.start)
                                              .inDays;
                                      return Text(
                                        duration <= 30
                                            ? "${DateTime.fromMillisecondsSinceEpoch(titleData.ceil()).day}."
                                            : (duration < 140
                                                ? "KW ${DateTime.fromMillisecondsSinceEpoch(titleData.ceil()).weekOfYear}"
                                                : switch (DateTime.fromMillisecondsSinceEpoch(
                                                  titleData.ceil(),
                                                ).month) {
                                                  2 => "Feb",
                                                  3 => "Mär",
                                                  4 => "Apr",
                                                  5 => "Mai",
                                                  6 => "Jun",
                                                  7 => "Jul",
                                                  8 => "Aug",
                                                  9 => "Sep",
                                                  10 => "Okt",
                                                  11 => "Nov",
                                                  12 => "Dez",
                                                  1 || _ => "Jan",
                                                }),
                                        style: TextStyle(fontSize: 13),
                                      );
                                    }(),
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
                                    ),
                                  )
                                  .toList(),
                          gridData: FlGridData(
                            horizontalInterval: max(
                              ((maxVal / 6) - ((maxVal / 6) % 10)).toDouble(),
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
            payments.isNotEmpty
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
      ),
    );
  }
}*/
