import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../basic_providers.dart';

final locationsProvider = realtimeCollectionProvider(
  FirebaseFirestore.instance.collection("locations"),
);

class LocationsPage extends ConsumerWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Scaffold(appBar: AppBar(title: Text("Standplätze")));
  }
}
