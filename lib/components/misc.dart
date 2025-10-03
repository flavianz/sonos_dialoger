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

  String toExtendedFormattedDateString() {
    return "$day. ${switch (month) {
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
    }}.";
  }

  String toFormattedDateTimeString() {
    return "${day.toString().padLeft(2, "0")}.${month.toString().padLeft(2, "0")}., ${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";
  }
}

DateTime parseDateTime(dynamic value) {
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
