import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../components/misc.dart';
import '../core/payment.dart';
import '../providers.dart';
import 'date_ranges.dart';

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
