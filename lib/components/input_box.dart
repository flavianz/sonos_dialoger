import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class InputBox extends StatelessWidget {
  final String title;
  final Widget widget;

  const InputBox({super.key, required this.title, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        widget,
        SizedBox(height: 10),
      ],
    );
  }

  factory InputBox.text(
    String title,
    String value,
    Function(String?) onChanged, {
    String? hint,
    bool password = false,
  }) {
    return InputBox(
      title: title,
      widget: TextFormField(
        initialValue: value,
        onChanged: onChanged,
        obscureText: password,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class DateRangeDropdown extends ConsumerWidget {
  const DateRangeDropdown({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 200),
      child: DropdownButtonFormField(
        value: ref.watch(timespanProvider),
        decoration: InputDecoration(
          hintText: "Zeitraum",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        ),
        items: [
          DropdownMenuItem(value: Timespan.today, child: Text("Heute")),
          DropdownMenuItem(value: Timespan.yesterday, child: Text("Gestern")),
          DropdownMenuItem(value: Timespan.week, child: Text("Diese Woche")),
          DropdownMenuItem(value: Timespan.month, child: Text("Dieser Monat")),
          DropdownMenuItem(
            value: Timespan.custom,
            child: Text("Benutzerdefiniert"),
          ),
        ],
        onChanged: (newValue) async {
          if (newValue == Timespan.today || newValue == Timespan.yesterday) {
            final now =
                newValue == Timespan.today
                    ? DateTime.now()
                    : DateTime.now().subtract(Duration(days: 1));
            ref.read(rangeProvider.notifier).state = DateTimeRange(
              start: DateTime(now.year, now.month, now.day),
              end: DateTime(
                now.year,
                now.month,
                now.day,
              ).add(Duration(days: 1)).subtract(Duration(milliseconds: 1)),
            );
          } else if (newValue == Timespan.week) {
            final now = DateTime.now();
            ref.read(rangeProvider.notifier).state = DateTimeRange(
              start: DateTime(now.year, now.month, now.day - now.weekday + 1),
              end: DateTime(
                now.year,
                now.month,
                now.day - now.weekday + 8,
              ).subtract(Duration(milliseconds: 1)),
            );
          } else if (newValue == Timespan.month) {
            final now = DateTime.now();
            ref.read(rangeProvider.notifier).state = DateTimeRange(
              start: DateTime(now.year, now.month, 0),
              end: DateTime(
                now.year,
                now.month + 1,
              ).subtract(Duration(milliseconds: 1)),
            );
          } else if (newValue == Timespan.custom) {
            final now = DateTime.now();
            final DateTimeRange? range = await showDateRangePicker(
              initialDateRange: ref.read(rangeProvider),
              locale: Locale("de"),
              context: context,
              firstDate: DateTime(0),
              lastDate: DateTime(now.year, now.month, now.day),
            );
            if (range != null) {
              ref.read(rangeProvider.notifier).state = DateTimeRange(
                start: range.start,
                end: range.end
                    .add(Duration(days: 1))
                    .subtract(Duration(milliseconds: 1)),
              );
            }
          }
          ref.read(timespanProvider.notifier).state =
              newValue ?? Timespan.today;
        },
      ),
    );
  }
}
