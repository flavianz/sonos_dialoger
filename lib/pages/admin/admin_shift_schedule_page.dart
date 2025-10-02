import 'package:flutter/material.dart';

class AdminShiftSchedulePage extends StatelessWidget {
  const AdminShiftSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Einteilung"),
          forceMaterialTransparency: true,
          bottom: TabBar(
            tabs: [
              Tab(text: "Anfragen", icon: Icon(Icons.new_releases_outlined)),
              Tab(text: "Kalender", icon: Icon(Icons.calendar_month)),
            ],
          ),
        ),
        body: TabBarView(children: [Center(), Center()]),
      ),
    );
  }
}
