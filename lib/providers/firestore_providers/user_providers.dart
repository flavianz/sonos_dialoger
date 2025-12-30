import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../core/payment.dart';
import '../../core/user.dart';
import '../firestore_providers.dart';

final nonAdminUsersProvider = StreamProvider.autoDispose<Iterable<SonosUser>>((
  ref,
) {
  return firestore
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
  final payment = Payment.fromDoc(
    await ref.watch(paymentProvider(paymentId).future),
  );
  return SonosUser.fromDoc(
    await firestore.collection("users").doc(payment.dialoger).get(),
  );
});

final dialogerProvider = FutureProvider.family.autoDispose<SonosUser, String>((
  ref,
  String dialogerId,
) async {
  return SonosUser.fromDoc(
    await firestore.collection("users").doc(dialogerId).get(),
  );
});

final liveDialogerProvider = StreamProvider.family
    .autoDispose<SonosUser, String>((ref, String dialogerId) {
      return firestore
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
    var docRef = firestore.collection('users').doc(user.uid);
    return docRef.snapshots().map((doc) => SonosUser.fromDoc(doc));
  } else {
    return Stream.empty();
  }
});
