import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CoachScheduleCalendar extends StatelessWidget {
  const CoachScheduleCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          FilledButton.icon(
            onPressed: () => context.push("/coach/schedules/new/2025/10/18"),
            label: Text("Neu"),
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
