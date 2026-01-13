import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:async/async.dart';

@immutable
class QueryByIdsArgs {
  final String queryKey;
  final List<dynamic> ids;

  const QueryByIdsArgs({required this.queryKey, required this.ids});

  @override
  bool operator ==(Object other) =>
      other is QueryByIdsArgs &&
      queryKey == other.queryKey &&
      listEquals(ids, other.ids);

  @override
  int get hashCode => Object.hash(queryKey, Object.hashAll(ids));
}

final queryByIdsProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, QueryByIdsArgs>((
      ref,
      args,
    ) {
      final baseQuery = args.queryKey;
      final ids = args.ids;

      if (ids.isEmpty) return Stream.value([]);
      final chunks = <List<dynamic>>[];
      for (var i = 0; i < ids.length; i += 10) {
        chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
      }

      final streams = chunks.map((chunk) {
        return FirebaseFirestore.instance
            .collection(baseQuery)
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .map((snap) => snap.docs);
      });

      return StreamGroup.merge(streams).map((chunks) {
        return chunks;
      });
    });
