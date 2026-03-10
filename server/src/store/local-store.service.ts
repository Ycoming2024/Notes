import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';
import * as path from 'path';

export type ChangeEntityType = 'note' | 'reminder' | 'tag';
export type ChangeOp = 'create' | 'update' | 'delete';

type User = {
  id: string;
  email: string;
  displayName?: string;
  createdAt: string;
  updatedAt: string;
};

type Device = {
  id: string;
  userId: string;
  platform: 'android' | 'windows';
  deviceName?: string;
  pushToken?: string;
  lastSeenAt?: string;
  createdAt: string;
};

type Note = {
  id: string;
  userId: string;
  title: string;
  content: string;
  color?: string;
  isPinned: boolean;
  isArchived: boolean;
  isDeleted: boolean;
  version: number;
  createdAt: string;
  updatedAt: string;
};

type Reminder = {
  id: string;
  userId: string;
  noteId?: string;
  title: string;
  body?: string;
  dueAt: string;
  timezone: string;
  repeatRule: string;
  status: string;
  snoozeUntil?: string;
  isDeleted: boolean;
  version: number;
  createdAt: string;
  updatedAt: string;
};

type ChangeLog = {
  id: number;
  userId: string;
  entityType: ChangeEntityType;
  entityId: string;
  op: ChangeOp;
  version: number;
  changedAt: string;
};

type DatabaseShape = {
  users: User[];
  devices: Device[];
  notes: Note[];
  reminders: Reminder[];
  changeLogs: ChangeLog[];
  seq: number;
};

const DEFAULT_DB: DatabaseShape = {
  users: [],
  devices: [],
  notes: [],
  reminders: [],
  changeLogs: [],
  seq: 0,
};

@Injectable()
export class LocalStoreService {
  private readonly filePath = path.resolve(process.cwd(), 'data', 'db.json');
  private db: DatabaseShape = { ...DEFAULT_DB };
  private loaded = false;

  private async ensureLoaded() {
    if (this.loaded) return;
    try {
      const raw = await fs.readFile(this.filePath, 'utf8');
      this.db = JSON.parse(raw) as DatabaseShape;
    } catch {
      await this.persist();
    }
    this.loaded = true;
  }

  private async persist() {
    await fs.mkdir(path.dirname(this.filePath), { recursive: true });
    await fs.writeFile(this.filePath, JSON.stringify(this.db, null, 2), 'utf8');
  }

  async ensureUser(userId: string) {
    await this.ensureLoaded();
    const now = new Date().toISOString();
    const existing = this.db.users.find((u) => u.id === userId);
    if (existing) return existing;
    const user: User = { id: userId, email: `${userId}@dev.local`, createdAt: now, updatedAt: now };
    this.db.users.push(user);
    await this.persist();
    return user;
  }

  async upsertUserByEmail(email: string) {
    await this.ensureLoaded();
    const now = new Date().toISOString();
    const existing = this.db.users.find((u) => u.email === email);
    if (existing) return existing;
    const user: User = { id: crypto.randomUUID(), email, createdAt: now, updatedAt: now };
    this.db.users.push(user);
    await this.persist();
    return user;
  }

  async createDevice(input: Omit<Device, 'id' | 'createdAt'>) {
    await this.ensureLoaded();
    const device: Device = { ...input, id: crypto.randomUUID(), createdAt: new Date().toISOString() };
    this.db.devices.push(device);
    await this.persist();
    return device;
  }

  async updatePushToken(userId: string, deviceId: string, pushToken: string) {
    await this.ensureLoaded();
    const target = this.db.devices.find((d) => d.id === deviceId && d.userId === userId);
    if (!target) return false;
    target.pushToken = pushToken;
    target.lastSeenAt = new Date().toISOString();
    await this.persist();
    return true;
  }

  async listNotes(userId: string, updatedAfter?: string, limit = 100) {
    await this.ensureLoaded();
    const since = updatedAfter ? new Date(updatedAfter).getTime() : 0;
    return this.db.notes
      .filter((n) => n.userId === userId && !n.isDeleted && new Date(n.updatedAt).getTime() > since)
      .sort((a, b) => +new Date(b.updatedAt) - +new Date(a.updatedAt))
      .slice(0, Math.min(limit, 500));
  }

  async createNote(input: Omit<Note, 'id' | 'version' | 'createdAt' | 'updatedAt' | 'isArchived' | 'isDeleted'>) {
    await this.ensureLoaded();
    const now = new Date().toISOString();
    const note: Note = {
      ...input,
      id: crypto.randomUUID(),
      isArchived: false,
      isDeleted: false,
      version: 1,
      createdAt: now,
      updatedAt: now,
    };
    this.db.notes.push(note);
    await this.persist();
    return note;
  }

  async updateNote(id: string, patch: Partial<Note>) {
    await this.ensureLoaded();
    const target = this.db.notes.find((n) => n.id === id);
    if (!target) return null;
    Object.assign(target, patch);
    target.version += 1;
    target.updatedAt = new Date().toISOString();
    await this.persist();
    return target;
  }

  async listReminders(userId: string, updatedAfter?: string, limit = 100) {
    await this.ensureLoaded();
    const since = updatedAfter ? new Date(updatedAfter).getTime() : 0;
    return this.db.reminders
      .filter((r) => r.userId === userId && !r.isDeleted && new Date(r.updatedAt).getTime() > since)
      .sort((a, b) => +new Date(a.dueAt) - +new Date(b.dueAt))
      .slice(0, Math.min(limit, 500));
  }

  async createReminder(input: Omit<Reminder, 'id' | 'version' | 'createdAt' | 'updatedAt' | 'isDeleted' | 'timezone' | 'status' | 'snoozeUntil'>) {
    await this.ensureLoaded();
    const now = new Date().toISOString();
    const reminder: Reminder = {
      ...input,
      id: crypto.randomUUID(),
      timezone: 'Asia/Shanghai',
      status: 'pending',
      isDeleted: false,
      version: 1,
      createdAt: now,
      updatedAt: now,
    };
    this.db.reminders.push(reminder);
    await this.persist();
    return reminder;
  }

  async updateReminder(id: string, patch: Partial<Reminder>) {
    await this.ensureLoaded();
    const target = this.db.reminders.find((r) => r.id === id);
    if (!target) return null;
    Object.assign(target, patch);
    target.version += 1;
    target.updatedAt = new Date().toISOString();
    await this.persist();
    return target;
  }

  async appendChange(change: Omit<ChangeLog, 'id' | 'changedAt'>) {
    await this.ensureLoaded();
    this.db.seq += 1;
    const row: ChangeLog = { ...change, id: this.db.seq, changedAt: new Date().toISOString() };
    this.db.changeLogs.push(row);
    await this.persist();
    return row;
  }

  async listChanges(userId: string, since?: string, limit = 500) {
    await this.ensureLoaded();
    const sinceMs = since ? new Date(since).getTime() : 0;
    return this.db.changeLogs
      .filter((c) => c.userId === userId && new Date(c.changedAt).getTime() > sinceMs)
      .sort((a, b) => +new Date(a.changedAt) - +new Date(b.changedAt))
      .slice(0, Math.min(limit, 500));
  }

  async getNote(id: string) {
    await this.ensureLoaded();
    return this.db.notes.find((n) => n.id === id) ?? null;
  }

  async getReminder(id: string) {
    await this.ensureLoaded();
    return this.db.reminders.find((r) => r.id === id) ?? null;
  }

  async upsertNoteById(input: {
    id: string;
    userId: string;
    title?: string;
    content?: string;
    color?: string;
    isPinned?: boolean;
    isDeleted?: boolean;
  }) {
    await this.ensureLoaded();
    const existing = this.db.notes.find((n) => n.id === input.id);
    if (existing) {
      Object.assign(existing, {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.content !== undefined ? { content: input.content } : {}),
        ...(input.color !== undefined ? { color: input.color } : {}),
        ...(input.isPinned !== undefined ? { isPinned: input.isPinned } : {}),
        ...(input.isDeleted !== undefined ? { isDeleted: input.isDeleted } : {}),
      });
      existing.version += 1;
      existing.updatedAt = new Date().toISOString();
      await this.persist();
      return existing;
    }

    const now = new Date().toISOString();
    const note: Note = {
      id: input.id,
      userId: input.userId,
      title: input.title ?? '',
      content: input.content ?? '',
      color: input.color,
      isPinned: input.isPinned ?? false,
      isArchived: false,
      isDeleted: input.isDeleted ?? false,
      version: 1,
      createdAt: now,
      updatedAt: now,
    };
    this.db.notes.push(note);
    await this.persist();
    return note;
  }

  async upsertReminderById(input: {
    id: string;
    userId: string;
    title?: string;
    body?: string;
    dueAt?: string;
    repeatRule?: string;
    isDeleted?: boolean;
  }) {
    await this.ensureLoaded();
    const existing = this.db.reminders.find((r) => r.id === input.id);
    if (existing) {
      Object.assign(existing, {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.body !== undefined ? { body: input.body } : {}),
        ...(input.dueAt !== undefined ? { dueAt: input.dueAt } : {}),
        ...(input.repeatRule !== undefined ? { repeatRule: input.repeatRule } : {}),
        ...(input.isDeleted !== undefined ? { isDeleted: input.isDeleted } : {}),
      });
      existing.version += 1;
      existing.updatedAt = new Date().toISOString();
      await this.persist();
      return existing;
    }

    const now = new Date().toISOString();
    const reminder: Reminder = {
      id: input.id,
      userId: input.userId,
      title: input.title ?? '',
      body: input.body,
      noteId: undefined,
      dueAt: input.dueAt ?? now,
      timezone: 'Asia/Shanghai',
      repeatRule: input.repeatRule ?? 'none',
      status: 'pending',
      snoozeUntil: undefined,
      isDeleted: input.isDeleted ?? false,
      version: 1,
      createdAt: now,
      updatedAt: now,
    };
    this.db.reminders.push(reminder);
    await this.persist();
    return reminder;
  }
}
