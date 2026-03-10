import '../../features/sync/data/sync_api.dart';
import '../storage/drift_db.dart';

class SyncManager {
  SyncManager({required this.db, required this.syncApi});

  final AppDatabase db;
  final SyncApi syncApi;

  DateTime _cursor = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Future<void> syncOnce({DateTime? since}) async {
    final effectiveSince = (since ?? _cursor).toUtc();
    await _pushLocalChanges();
    final pulled = await syncApi.pullChanges(effectiveSince);
    await _applyRemoteChanges(pulled.changes);
    _cursor = pulled.nextSince;
    await syncApi.ack(_cursor);
  }

  Future<void> forceFullSync() async {
    _cursor = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    await syncOnce(since: _cursor);
  }

  Future<int> pendingCount() {
    return db.countPendingChanges();
  }

  Future<void> _pushLocalChanges() async {
    final pending = await db.listPendingChanges();
    if (pending.isEmpty) return;

    final changes = pending
        .map(
          (e) => {
            'entity_type': e.entityType,
            'entity_id': e.entityId,
            'op': e.op,
            'payload': e.payload,
            'updated_at': e.updatedAt.toUtc().toIso8601String(),
          },
        )
        .toList();

    await syncApi.pushChanges(changes);
    await db.removePendingChanges(pending.map((e) => e.id).toList());
  }

  Future<void> _applyRemoteChanges(List<Map<String, dynamic>> changes) async {
    for (final item in changes) {
      final entityType = item['entityType'] ?? item['entity_type'];
      final payload =
          (item['payload'] as Map?)?.cast<String, dynamic>() ?? item;
      if (entityType == 'note') {
        await db.upsertNoteFromRemote(payload);
      }
      if (entityType == 'reminder') {
        await db.upsertReminderFromRemote(payload);
      }
    }
  }
}
