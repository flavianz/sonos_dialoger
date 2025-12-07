import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/dialoger/dialoger_schedule_page.dart';
import 'misc.dart';

class ScheduleTimespanDropdown extends ConsumerWidget {
  const ScheduleTimespanDropdown({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final scheduleStartDate = ref.watch(scheduleStartDateProvider);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 150),
      child: DropdownButtonFormField(
        initialValue: ref.watch(scheduleTimespanProvider),
        decoration: InputDecoration(
          hintText: "Zeitraum",
          border: InputBorder.none,
        ),
        items: [
          DropdownMenuItem(value: ScheduleTimespan.day, child: Text("Tag")),
          DropdownMenuItem(value: ScheduleTimespan.week, child: Text("Woche")),
          DropdownMenuItem(value: ScheduleTimespan.month, child: Text("Monat")),
        ],
        onChanged: (newValue) {
          if (newValue != null) {
            ref.read(scheduleTimespanProvider.notifier).state = newValue;
            if (newValue == ScheduleTimespan.week) {
              ref.read(scheduleStartDateProvider.notifier).state =
                  scheduleStartDate.getWeekStart();
            } else if (newValue == ScheduleTimespan.month) {
              ref.read(scheduleStartDateProvider.notifier).state =
                  scheduleStartDate.getMonthStart();
            }
          }
        },
      ),
    );
  }
}
