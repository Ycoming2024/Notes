import { Injectable } from '@nestjs/common';
import { LocalStoreService } from '../store/local-store.service';
import { PushSyncDto } from './dto/sync.dto';

@Injectable()
export class SyncService {
  constructor(private readonly store: LocalStoreService) {}

  async push(userId: string, dto: PushSyncDto) {
    await this.store.ensureUser(userId);
    for (const change of dto.changes) {
      const payload = JSON.parse(change.payload || '{}') as Record<string, unknown>;
      if (change.entity_type === 'note') {
        const note = await this.store.upsertNoteById({
          id: change.entity_id,
          userId,
          title: payload.title as string | undefined,
          content: payload.content as string | undefined,
          color: payload.color as string | undefined,
          isPinned: payload.is_pinned as boolean | undefined,
          isDeleted: change.op === 'delete',
        });
        await this.store.appendChange({
          userId,
          entityType: 'note',
          entityId: note.id,
          op: change.op,
          version: note.version,
        });
      }

      if (change.entity_type === 'reminder') {
        const reminder = await this.store.upsertReminderById({
          id: change.entity_id,
          userId,
          title: payload.title as string | undefined,
          body: payload.body as string | undefined,
          dueAt: payload.due_at as string | undefined,
          repeatRule: payload.repeat_rule as string | undefined,
          isDeleted: change.op === 'delete',
        });
        await this.store.appendChange({
          userId,
          entityType: 'reminder',
          entityId: reminder.id,
          op: change.op,
          version: reminder.version,
        });
      }
    }

    return { ok: true, accepted: dto.changes.length };
  }

  async pull(userId: string, since?: string, limit = 500) {
    const changes = await this.store.listChanges(userId, since, limit);
    const hydratedChanges: Array<Record<string, unknown>> = [];

    for (const change of changes) {
      let payload: Record<string, unknown> = {};
      if (change.entityType === 'note') {
        const note = await this.store.getNote(change.entityId);
        if (note) {
          payload = {
            id: note.id,
            title: note.title,
            content: note.content,
            color: note.color,
            is_pinned: note.isPinned,
            is_deleted: note.isDeleted,
            version: note.version,
            updated_at: note.updatedAt,
          };
        }
      }
      if (change.entityType === 'reminder') {
        const reminder = await this.store.getReminder(change.entityId);
        if (reminder) {
          payload = {
            id: reminder.id,
            note_id: reminder.noteId,
            title: reminder.title,
            body: reminder.body,
            due_at: reminder.dueAt,
            repeat_rule: reminder.repeatRule,
            status: reminder.status,
            snooze_until: reminder.snoozeUntil,
            is_deleted: reminder.isDeleted,
            version: reminder.version,
            updated_at: reminder.updatedAt,
          };
        }
      }
      hydratedChanges.push({
        entity_type: change.entityType,
        entity_id: change.entityId,
        op: change.op,
        payload,
        updated_at: change.changedAt,
      });
    }

    const nextSince = changes.length > 0 ? changes[changes.length - 1].changedAt : (since ?? new Date(0).toISOString());
    return { changes: hydratedChanges, next_since: nextSince };
  }

  async ack(since: string) {
    return { ok: true, since };
  }
}
