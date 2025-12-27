import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonos_dialoger/core/location.dart';

import '../../app.dart';
import '../../components/misc.dart';
import '../../core/payment.dart';
import '../../providers.dart';
import '../firestore_providers.dart';

final allLocationsProvider = StreamProvider.autoDispose<Iterable<Location>>((
  ref,
) {
  return firestore
      .collection("locations")
      .snapshots()
      .map((doc) => doc.docs.map((doc) => Location.fromDoc(doc)));
});

final personnelAssignedSchedulesLocationsProvider =
    StreamProvider<Iterable<Location>>((ref) {
      final schedules = ref.watch(personnelAssignedSchedulesProvider);
      if (schedules.isLoading) {
        return Stream.empty();
      }
      if (schedules.hasError) {
        return Stream.error(schedules.error ?? "Unknown error");
      }
      final scheduleDocs = schedules.value!.docs;
      final locationIds = flatten(
        scheduleDocs.map((doc) {
          return doc.data()["confirmed_locations"] ?? [];
        }),
      );
      final locations = ref.watch(
        queryByIdsProvider(
          QueryByIdsArgs(
            queryKey: "locations",
            ids: locationIds.toSet().toList(),
          ),
        ),
      );
      if (locations.isLoading) {
        return Stream.empty();
      }
      if (locations.hasError) {
        return Stream.error(locations.error ?? "Unknown error");
      }
      return Stream.value(locations.value!.map((doc) => Location.fromDoc(doc)));
    });

final confirmedLocationsProvider =
    StreamProvider.family<Iterable<Location>, String>((ref, String scheduleId) {
      final schedule = ref.watch(scheduleProvider(scheduleId));
      if (schedule.hasError) {
        return Stream.error(schedule.error!);
      }
      if (schedule.isLoading) {
        return Stream.empty();
      }

      final scheduleData = schedule.value?.data() ?? {};

      List<dynamic> confirmedLocations = scheduleData["confirmed_locations"];

      return firestore
          .collection("locations")
          .where(FieldPath.documentId, whereIn: confirmedLocations)
          .snapshots()
          .map((doc) => doc.docs.map((doc) => Location.fromDoc(doc)));
    });

final schedulesLocationsProvider = StreamProvider<Iterable<Location>>((ref) {
  final schedules = ref.watch(schedulesProvider);
  if (schedules.isLoading) {
    return Stream.empty();
  }
  if (schedules.hasError) {
    return Stream.error(schedules.error ?? "Unknown error");
  }
  final scheduleDocs = schedules.value!.docs;
  final locationIds = flatten(
    scheduleDocs.map((doc) {
      return doc.data()["reviewed"] == true
          ? (doc.data()["confirmed_locations"] ?? [])
          : (doc.data()["requested_locations"] ?? []);
    }),
  );

  return Stream.fromFuture(
    ref.read(
      queryByIdsProvider(
        QueryByIdsArgs(
          queryKey: "locations",
          ids: locationIds.toSet().toList(),
        ),
      ).future,
    ),
  ).map((doc) => doc.map((doc) => Location.fromDoc(doc)));
});

final requestedLocationsProvider =
    StreamProvider.family<Iterable<Location>, String>((
      ref,
      String scheduleId, // Changed from List to String
    ) {
      // Watch the new provider to get the list of IDs
      final locationIds = ref.watch(scheduleLocationIdsProvider(scheduleId));

      // If there are no IDs, return an empty stream to avoid an error
      if (locationIds.isEmpty) {
        return Stream.empty();
      }

      if (locationIds.length > 30) {
        throw ErrorDescription("Too many locations provided (>30)");
      }

      return firestore
          .collection("locations")
          .where(FieldPath.documentId, whereIn: locationIds)
          .snapshots()
          .map((doc) => doc.docs.map((doc) => Location.fromDoc(doc)));
    });

final paymentLocationProvider = FutureProvider.family((
  ref,
  String paymentId,
) async {
  final payment = Payment.fromDoc(
    await ref.watch(paymentProvider(paymentId).future),
  );
  return Location.fromDoc(
    await FirebaseFirestore.instance
        .collection("locations")
        .doc(payment.location)
        .get(),
  );
});

final locationProvider = StreamProvider.family((ref, String locationId) {
  return firestore
      .collection("locations")
      .doc(locationId)
      .snapshots()
      .map((doc) => Location.fromDoc(doc));
});
