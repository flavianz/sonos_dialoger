import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../components/misc.dart';
import '../core/payment.dart';
import '../providers.dart';
import 'date_ranges.dart';

final allLocationsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return firestore.collection("locations").snapshots();
    });

final confirmedSchedulesProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return firestore
          .collection("schedules")
          .where(
            Filter.and(
              Filter("reviewed", isEqualTo: true),
              Filter("personnel_assigned", isEqualTo: false),
            ),
          )
          .orderBy("date")
          .snapshots();
    });
final nonAdminUsersProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return firestore
          .collection("users")
          .where("role", isNotEqualTo: "admin")
          .orderBy("role")
          .orderBy("first")
          .snapshots();
    });

final scheduleProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      String scheduleId,
    ) {
      return firestore.collection("schedules").doc(scheduleId).snapshots();
    });

final paymentProvider = FutureProvider.family(
  (ref, String id) =>
      FirebaseFirestore.instance.collection("payments").doc(id).get(),
);

final todayScheduleProvider = StreamProvider((ref) {
  return firestore
      .collection("schedules")
      .where(
        Filter.and(
          Filter(
            "date",
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().getDayStart(),
            ),
          ),
          Filter(
            "date",
            isLessThan: Timestamp.fromDate(
              DateTime.now().add(Duration(days: 1)).getDayStart(),
            ),
          ),
          Filter("personnel_assigned", isEqualTo: true),
        ),
      )
      .snapshots();
});

final localDialogerPaymentsProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return FirebaseFirestore.instance
          .collection("payments")
          .where(
            Filter.and(
              ref.watch(paymentsDateFilterProvider),
              Filter(
                "dialoger",
                isEqualTo: ref.watch(userProvider).value?.uid ?? "",
              ),
            ),
          )
          .orderBy("timestamp", descending: true)
          .snapshots();
    });

final personnelAssignedSchedulesProvider = StreamProvider((ref) {
  final scheduleTimespan = ref.watch(scheduleTimespanProvider);
  final scheduleStartDate = ref.watch(scheduleStartDateProvider);

  late final DateTime endDate;
  if (scheduleTimespan == Timespan.day) {
    endDate = scheduleStartDate.add(Duration(days: 1));
  } else if (scheduleTimespan == Timespan.week) {
    endDate = scheduleStartDate.add(Duration(days: 7));
  } else {
    endDate = DateTime(scheduleStartDate.year, scheduleStartDate.month + 1);
  }

  return firestore
      .collection("schedules")
      .where(
        Filter.and(
          Filter(
            "date",
            isGreaterThanOrEqualTo: Timestamp.fromDate(scheduleStartDate),
          ),
          Filter("date", isLessThan: Timestamp.fromDate(endDate)),
          Filter("personnel_assigned", isEqualTo: true),
        ),
      )
      .snapshots();
});

final personnelAssignedSchedulesLocationsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>((ref) {
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
      return Stream.value(locations.value);
    });

final confirmedLocationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>((
      ref,
      String scheduleId,
    ) {
      final schedule = ref.watch(scheduleProvider(scheduleId));
      if (schedule.hasError) {
        return Stream.error(schedule.error!);
      }
      if (schedule.isLoading) {
        return Stream.empty();
      }

      final scheduleData = schedule.value?.data() ?? {};

      List<dynamic> confirmedLocations = scheduleData["confirmed_locations"];

      return FirebaseFirestore.instance
          .collection("locations")
          .where(FieldPath.documentId, whereIn: confirmedLocations)
          .snapshots();
    });

final schedulesProvider = StreamProvider((ref) {
  final scheduleTimespan = ref.watch(scheduleTimespanProvider);
  final scheduleStartDate = ref.watch(scheduleStartDateProvider);

  late final DateTime endDate;
  if (scheduleTimespan == Timespan.day) {
    endDate = scheduleStartDate.add(Duration(days: 1));
  } else if (scheduleTimespan == Timespan.week) {
    endDate = scheduleStartDate.add(Duration(days: 7));
  } else {
    endDate = DateTime(scheduleStartDate.year, scheduleStartDate.month + 1);
  }

  return firestore
      .collection("schedules")
      .where(
        Filter.and(
          Filter(
            "date",
            isGreaterThanOrEqualTo: Timestamp.fromDate(scheduleStartDate),
          ),
          Filter("date", isLessThan: Timestamp.fromDate(endDate)),
        ),
      )
      .snapshots();
});

final schedulesLocationsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>?>((ref) {
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
      );
    });

final scheduleLocationIdsProvider = Provider.family<List<dynamic>, String>((
  ref,
  scheduleId,
) {
  final scheduleAsyncValue = ref.watch(scheduleProvider(scheduleId));
  final data = scheduleAsyncValue.value?.data() ?? {};

  // When data is available, return the locations list, otherwise return an empty list.
  return [
    ...(data["requested_locations"] ?? []),
    ...(data["added_locations"] ?? []),
  ];
});

final requestedLocationsProvider =
    StreamProvider.family<QuerySnapshot<Map<String, dynamic>>, String>((
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

      return FirebaseFirestore.instance
          .collection("locations")
          .where(FieldPath.documentId, whereIn: locationIds)
          .snapshots();
    });

final paymentsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection("payments")
      .where(ref.watch(paymentsDateFilterProvider))
      .orderBy("timestamp", descending: true)
      .snapshots();
});

final paymentLocationProvider = FutureProvider.family((
  ref,
  String paymentId,
) async {
  final payment = Payment.fromDoc(
    await ref.watch(paymentProvider(paymentId).future),
  );
  return FirebaseFirestore.instance
      .collection("locations")
      .doc(payment.location)
      .get();
});

final dialogerProvider = FutureProvider.family((ref, String paymentId) async {
  final payment = Payment.fromDoc(
    await ref.watch(paymentProvider(paymentId).future),
  );
  return FirebaseFirestore.instance
      .collection("users")
      .doc(payment.dialoger)
      .get();
});

final locationProvider = StreamProvider.family((ref, String locationId) {
  return firestore.collection("locations").doc(locationId).snapshots();
});

final locationPaymentsProvider = StreamProvider.family((
  ref,
  String locationId,
) {
  return FirebaseFirestore.instance
      .collection("payments")
      .where(
        Filter.and(
          ref.watch(paymentsDateFilterProvider),
          Filter("location", isEqualTo: locationId),
        ),
      )
      .orderBy("timestamp", descending: true)
      .snapshots();
});

final dialogerFutureProvider = FutureProvider.family.autoDispose<
  DocumentSnapshot<Map<String, dynamic>>,
  String
>((ref, String dialogerId) {
  return FirebaseFirestore.instance.collection("users").doc(dialogerId).get();
});

final scheduleRequestsProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
      return FirebaseFirestore.instance
          .collection("schedules")
          .where("reviewed", isEqualTo: false)
          .orderBy("date")
          .snapshots();
    });
