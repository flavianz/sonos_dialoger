import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/payment.dart';
import '../../core/user.dart';
import '../firestore_providers.dart';

final nonAdminUsersProvider = StreamProvider.autoDispose<Iterable<SonosUser>>((
  ref,
) {
  ref.watch(userProvider);
  return FirebaseFirestore.instance
      .collection("users")
      .where("role", isNotEqualTo: "admin")
      .orderBy("role")
      .orderBy("first")
      .snapshots()
      .map((docs) => docs.docs.map(SonosUser.fromDoc));
});

final paymentDialogerProvider = FutureProvider.family((
  ref,
  String paymentId,
) async {
  ref.watch(userProvider);
  final payment = Payment.fromDoc(
    await ref.watch(paymentProvider(paymentId).future),
  );
  return SonosUser.fromDoc(
    await FirebaseFirestore.instance
        .collection("users")
        .doc(payment.dialoger)
        .get(),
  );
});

final dialogerProvider = FutureProvider.family.autoDispose<SonosUser, String>((
  ref,
  String dialogerId,
) async {
  ref.watch(userProvider);
  return SonosUser.fromDoc(
    await FirebaseFirestore.instance.collection("users").doc(dialogerId).get(),
  );
});

final liveDialogerProvider = StreamProvider.family
    .autoDispose<SonosUser, String>((ref, String dialogerId) {
      ref.watch(userProvider);
      return FirebaseFirestore.instance
          .collection("users")
          .doc(dialogerId)
          .snapshots()
          .map(SonosUser.fromDoc);
    });

final userDataProvider = StreamProvider<SonosUser>((ref) {
  final userStream = ref.watch(userProvider);
  if (userStream.value != null) {
    userStream.value!.getIdToken(true);
  }

  var user = userStream.value;

  if (user != null) {
    var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    return docRef.snapshots().map((doc) => SonosUser.fromDoc(doc));
  } else {
    return Stream.empty();
  }
});
