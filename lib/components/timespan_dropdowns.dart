import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/date_ranges.dart';
import 'misc.dart';

class ScheduleTimespanDropdown extends ConsumerWidget {
  const ScheduleTimespanDropdown({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100),
      child: DropdownButtonFormField(
        initialValue: ref.watch(scheduleTimespanProvider),
        decoration: InputDecoration(
          hintText: "Zeitraum",
          border: InputBorder.none,
        ),
        items: [
          DropdownMenuItem(value: Timespan.day, child: Text("Tag")),
          DropdownMenuItem(value: Timespan.week, child: Text("Woche")),
          DropdownMenuItem(value: Timespan.month, child: Text("Monat")),
        ],
        onChanged: (newValue) {
          if (newValue != null) {
            ref.read(scheduleTimespanProvider.notifier).state = newValue;
            if (newValue == Timespan.week) {
              ref.read(scheduleStartDateProvider.notifier).state =
                  scheduleStartDate.getWeekStart();
            } else if (newValue == Timespan.month) {
              ref.read(scheduleStartDateProvider.notifier).state =
                  scheduleStartDate.getMonthStart();
            }
          }
        },
      ),
    );
  }
}

class PaymentsTimespanDropdown extends ConsumerWidget {
  const PaymentsTimespanDropdown({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final paymentsStartDate = ref.watch(paymentsStartDateProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 100),
      child: DropdownButtonFormField(
        initialValue: ref.watch(paymentsTimespanProvider),
        decoration: InputDecoration(
          hintText: "Zeitraum",
          border: InputBorder.none,
        ),
        items: [
          DropdownMenuItem(value: Timespan.day, child: Text("Tag")),
          DropdownMenuItem(value: Timespan.week, child: Text("Woche")),
          DropdownMenuItem(value: Timespan.month, child: Text("Monat")),
        ],
        onChanged: (newValue) {
          if (newValue != null) {
            ref.read(paymentsTimespanProvider.notifier).state = newValue;
            if (newValue == Timespan.week) {
              ref.read(paymentsStartDateProvider.notifier).state =
                  paymentsStartDate.getWeekStart();
            } else if (newValue == Timespan.month) {
              ref.read(paymentsStartDateProvider.notifier).state =
                  paymentsStartDate.getMonthStart();
            }
          }
        },
      ),
    );
  }
}

class PaymentsTimespanBar extends ConsumerWidget {
  const PaymentsTimespanBar({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final startDate = ref.watch(paymentsStartDateProvider);
    final timespan = ref.watch(paymentsTimespanProvider);
    final String yearSuffix = startDate.year == DateTime.now().year
        ? ""
        : " ${startDate.year}";
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        PaymentsTimespanDropdown(),
        SizedBox(height: 30, child: VerticalDivider()),
        IconButton(
          onPressed: () {
            if (timespan == Timespan.day) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addDays(-1);
            } else if (timespan == Timespan.week) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addDays(-7);
            } else if (timespan == Timespan.month) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addMonths(-1);
            }
          },
          icon: Icon(Icons.arrow_left),
        ),
        Text(switch (timespan) {
          Timespan.day =>
            "${startDate.day}. ${startDate.getMonthName()}$yearSuffix",
          Timespan.week =>
            "KW ${startDate.weekOfYear}${startDate.addDays(6).year == DateTime.now().year ? "" : " ${startDate.addDays(6).year}"}",
          Timespan.month => "${startDate.getMonthName()}$yearSuffix",
        }),
        IconButton(
          onPressed: () {
            if (timespan == Timespan.day) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addDays(1);
            } else if (timespan == Timespan.week) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addDays(7);
            } else if (timespan == Timespan.month) {
              ref.read(paymentsStartDateProvider.notifier).state = startDate
                  .addMonths(1);
            }
          },
          icon: Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}
