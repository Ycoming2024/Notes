import { Injectable, NotFoundException } from '@nestjs/common';
import { LocalStoreService } from '../store/local-store.service';
import { CreateReminderDto, UpdateReminderDto } from './dto/reminders.dto';

@Injectable()
export class RemindersService {
  constructor(private readonly store: LocalStoreService) {}

  async list(userId: string, updatedAfter?: string, limit = 100) {
    await this.store.ensureUser(userId);
    return this.store.listReminders(userId, updatedAfter, limit);
  }

  async create(userId: string, dto: CreateReminderDto) {
    await this.store.ensureUser(userId);
    const reminder = await this.store.createReminder({
      userId,
      noteId: dto.note_id,
      title: dto.title,
      body: dto.body,
      dueAt: new Date(dto.due_at).toISOString(),
      repeatRule: dto.repeat_rule,
    });
    await this.store.appendChange({
      userId,
      entityType: 'reminder',
      entityId: reminder.id,
      op: 'create',
      version: reminder.version,
    });
    return reminder;
  }

  async update(userId: string, id: string, dto: UpdateReminderDto) {
    const reminder = await this.store.updateReminder(id, {
      ...(dto.title !== undefined ? { title: dto.title } : {}),
      ...(dto.body !== undefined ? { body: dto.body } : {}),
      ...(dto.due_at !== undefined ? { dueAt: new Date(dto.due_at).toISOString() } : {}),
      ...(dto.repeat_rule !== undefined ? { repeatRule: dto.repeat_rule } : {}),
    });
    if (!reminder) throw new NotFoundException('Reminder not found');
    await this.store.appendChange({
      userId,
      entityType: 'reminder',
      entityId: reminder.id,
      op: 'update',
      version: reminder.version,
    });
    return reminder;
  }

  async done(userId: string, id: string) {
    const reminder = await this.store.updateReminder(id, { status: 'done' });
    if (!reminder) throw new NotFoundException('Reminder not found');
    await this.store.appendChange({
      userId,
      entityType: 'reminder',
      entityId: reminder.id,
      op: 'update',
      version: reminder.version,
    });
    return reminder;
  }

  async snooze(userId: string, id: string, minutes: number) {
    const snoozeUntil = new Date(Date.now() + minutes * 60 * 1000).toISOString();
    const reminder = await this.store.updateReminder(id, { snoozeUntil });
    if (!reminder) throw new NotFoundException('Reminder not found');
    await this.store.appendChange({
      userId,
      entityType: 'reminder',
      entityId: reminder.id,
      op: 'update',
      version: reminder.version,
    });
    return reminder;
  }

  async remove(userId: string, id: string) {
    const reminder = await this.store.updateReminder(id, { isDeleted: true });
    if (!reminder) throw new NotFoundException('Reminder not found');
    await this.store.appendChange({
      userId,
      entityType: 'reminder',
      entityId: reminder.id,
      op: 'delete',
      version: reminder.version,
    });
    return reminder;
  }
}
