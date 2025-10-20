import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';

enum ScheduleTimespan { day, week, month }

final scheduleTimespanProvider = StateProvider<ScheduleTimespan>(
  (ref) => ScheduleTimespan.week,
);

final scheduleStartDateProvider = StateProvider<DateTime>((ref) {
  final scheduleTimespan = ref.read(scheduleTimespanProvider);
  final now = DateTime.now();
  if (scheduleTimespan == ScheduleTimespan.day) {
    return DateTime(now.year, now.month, now.day);
  } else if (scheduleTimespan == ScheduleTimespan.week) {
    return now.getWeekStart();
  } else {
    return DateTime(now.year, now.month);
  }
});

class DialogerSchedulePage extends ConsumerWidget {
  const DialogerSchedulePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Einteilung"),
        actions: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 200),
            child: DropdownButtonFormField(
              initialValue: ref.watch(scheduleTimespanProvider),
              decoration: InputDecoration(
                hintText: "Zeitraum",
                border: InputBorder.none,
              ),
              items: [
                DropdownMenuItem(
                  value: ScheduleTimespan.day,
                  child: Text("Heute"),
                ),
                DropdownMenuItem(
                  value: ScheduleTimespan.week,
                  child: Text("Woche"),
                ),
                DropdownMenuItem(
                  value: ScheduleTimespan.month,
                  child: Text("Monat"),
                ),
              ],
              onChanged: (newValue) {
                if (newValue != null) {
                  ref.read(scheduleTimespanProvider.notifier).state = newValue;
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Text(switch (ref.watch(scheduleTimespanProvider)) {
                ScheduleTimespan.day =>
                  ref.watch(scheduleStartDateProvider).getMonthName() +
                      (ref.watch(scheduleStartDateProvider).year !=
                              DateTime.now().year
                          ? (ref.watch(scheduleStartDateProvider).year % 100)
                              .toString()
                              .padLeft(2, "0")
                          : ""),
                ScheduleTimespan.week => () {
                  return "";
                }(),
                ScheduleTimespan.month => throw UnimplementedError(),
              }),
            ],
          ),
        ],
      ),
    );
  }
}
