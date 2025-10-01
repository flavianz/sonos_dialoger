import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Timespan { today, yesterday, week, month, custom }

final timespanProvider = StateProvider<Timespan>((_) => Timespan.today);
final rangeProvider = StateProvider((_) {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  final tomorrow = DateTime.now().add(Duration(days: 1));
  return DateTimeRange(
    start: DateTime(yesterday.year, yesterday.month, yesterday.day),
    end: DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    ).subtract(Duration(milliseconds: 1)),
  );
});
