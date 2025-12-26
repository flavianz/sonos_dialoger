import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Widget getPill(String s, Color c, bool lightText) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      s,
      style: TextStyle(fontSize: 12, color: lightText ? Colors.white : null),
    ),
  );
}

void showSnackBar(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
    );
  }
}

extension DateTimeFormatExtension on DateTime {
  String toFormattedDateString() {
    return "${day.toString().padLeft(2, "0")}.${month.toString().padLeft(2, "0")}.";
  }

  String getMonthName() {
    return switch (month) {
      2 => "Februar",
      3 => "März",
      4 => "April",
      5 => "Mai",
      6 => "Juni",
      7 => "Juli",
      8 => "August",
      9 => "September",
      10 => "Oktober",
      11 => "November",
      12 => "Dezember",
      1 || _ => "Januar",
    };
  }

  String toExtendedFormattedDateString() {
    return "$day. ${getMonthName()}";
  }

  DateTime getWeekStart() {
    return DateTime(year, month, day).subtract(Duration(days: weekday - 1));
  }

  DateTime getDayStart() {
    return DateTime(year, month, day);
  }

  DateTime getMonthStart() {
    return DateTime(year, month);
  }

  String toFormattedDateTimeString() {
    return "${day.toString().padLeft(2, "0")}.${month.toString().padLeft(2, "0")}., ${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  DateTime addDays(int days) {
    return DateTime(year, month, day + days, hour, minute, second, millisecond);
  }

  DateTime addMonths(int months) {
    return DateTime(
      year,
      month + months,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  int getMonthDayCount() {
    return addMonths(1).addDays(-1).day;
  }

  String getWeekdayAbbreviation() {
    return switch (weekday) {
      2 => "Di",
      3 => "Mi",
      4 => "Do",
      5 => "Fr",
      6 => "Sa",
      7 => "So",
      _ => "Mo",
    };
  }

  String getWeekday() {
    return switch (weekday) {
      2 => "Dienstag",
      3 => "Mittwoch",
      4 => "Donnerstag",
      5 => "Freitag",
      6 => "Samstag",
      7 => "Sonntag",
      _ => "Montag",
    };
  }
}

DateTime parseDateTimeFromTimestamp(dynamic value) {
  return ((value ?? Timestamp.now()) as Timestamp).toDate();
}

class Tappable extends StatelessWidget {
  final Function()? onTap;
  final Widget? child;

  const Tappable({super.key, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
    );
  }
}

Widget errorHandling(object, stackTrace) {
  print(object);
  print(stackTrace);
  return Center(child: Text("Ups, hier hat etwas nicht geklappt"));
}

Widget loadingHandling() {
  return Center(child: CircularProgressIndicator());
}

List<T> flatten<T>(Iterable list) {
  return [for (var sublist in list) ...sublist];
}

extension ContainsWhere<T> on Iterable<T> {
  bool containsWhere(bool Function(T) test) {
    return where(test).isEmpty;
  }
}

extension ScreenWidth on BuildContext {
  bool get isScreenWide {
    return MediaQuery.of(this).size.aspectRatio > 1;
  }
}
