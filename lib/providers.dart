import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:async/async.dart';

import 'app.dart';

enum Timespan { today, yesterday, week, month, custom }

final timespanProvider = StateProvider<Timespan>((_) => Timespan.today);
final rangeProvider = StateProvider((_) {
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  final tomorrow = DateTime.now().add(Duration(days: 1));
  return DateTimeRange(
    start: DateTime(yesterday.year, yesterday.month, yesterday.day),
    end: DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    ).subtract(Duration(milliseconds: 1)),
  );
});

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
        return firestore
            .collection(baseQuery)
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .map((snap) => snap.docs);
      });

      return StreamGroup.merge(streams).map((chunks) {
        return chunks;
      });
    });
