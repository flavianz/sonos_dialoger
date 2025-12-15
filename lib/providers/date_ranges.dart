import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/components/misc.dart';

enum Timespan { day, week, month }

final paymentsTimespanProvider = StateProvider<Timespan>((_) => Timespan.week);
final paymentsStartDateProvider = StateProvider<DateTime>((ref) {
  final scheduleTimespan = ref.read(scheduleTimespanProvider);
  final now = DateTime.now();
  if (scheduleTimespan == Timespan.day) {
    return now.getDayStart();
  } else if (scheduleTimespan == Timespan.week) {
    return now.getWeekStart();
  } else {
    return now.getMonthStart();
  }
});

final scheduleTimespanProvider = StateProvider<Timespan>(
  (ref) => Timespan.week,
);

final scheduleStartDateProvider = StateProvider<DateTime>((ref) {
  final scheduleTimespan = ref.read(scheduleTimespanProvider);
  final now = DateTime.now();
  if (scheduleTimespan == Timespan.day) {
    return now.getDayStart();
  } else if (scheduleTimespan == Timespan.week) {
    return now.getWeekStart();
  } else {
    return now.getMonthStart();
  }
});

StateProvider<Filter> paymentsDateFilterProvider = StateProvider((ref) {
  final startDate = ref.watch(paymentsStartDateProvider);
  return switch (ref.watch(paymentsTimespanProvider)) {
    Timespan.day => Filter.and(
      Filter(
        "timestamp",
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.getDayStart()),
      ),
      Filter(
        "timestamp",
        isLessThan: Timestamp.fromDate(startDate.addDays(1).getDayStart()),
      ),
    ),
    Timespan.week => Filter.and(
      Filter(
        "timestamp",
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.getWeekStart()),
      ),
      Filter(
        "timestamp",
        isLessThan: Timestamp.fromDate(startDate.addDays(7).getWeekStart()),
      ),
    ),
    Timespan.month => Filter.and(
      Filter(
        "timestamp",
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.getMonthStart()),
      ),
      Filter(
        "timestamp",
        isLessThan: Timestamp.fromDate(startDate.addMonths(1).getMonthStart()),
      ),
    ),
  };
});
