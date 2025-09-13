import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallableProviderArgs extends Equatable {
  final String name;
  final Map<String, dynamic> data;

  const CallableProviderArgs(this.name, this.data);

  @override
  List<Object?> get props => [name, data];
}

final callableProvider = FutureProvider.autoDispose
    .family<HttpsCallableResult<dynamic>, CallableProviderArgs>((
      ref,
      args,
    ) async {
      return (await FirebaseFunctions.instanceFor(
        region: "europe-west3",
      ).httpsCallable(args.name).call(args.data));
    });

final realtimeDocProvider = StreamProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>
>((ref, DocumentReference<Map<String, dynamic>> docRef) {
  return docRef.snapshots();
});

final staticDocProvider = FutureProvider.family<
  DocumentSnapshot<Map<String, dynamic>>,
  DocumentReference<Map<String, dynamic>>
>((ref, DocumentReference<Map<String, dynamic>> docRef) {
  return docRef.get();
});

final realtimeCollectionProvider = StreamProvider.family<
  QuerySnapshot<Map<String, dynamic>>,
  Query<Map<String, dynamic>>
>((ref, Query<Map<String, dynamic>> collectionRef) {
  return collectionRef.snapshots();
});
