import { Injectable, NotFoundException } from '@nestjs/common';
import { LocalStoreService } from '../store/local-store.service';
import { CreateNoteDto, UpdateNoteDto } from './dto/notes.dto';

@Injectable()
export class NotesService {
  constructor(private readonly store: LocalStoreService) {}

  async list(userId: string, updatedAfter?: string, limit = 100) {
    await this.store.ensureUser(userId);
    return this.store.listNotes(userId, updatedAfter, limit);
  }

  async create(userId: string, dto: CreateNoteDto) {
    await this.store.ensureUser(userId);
    const note = await this.store.createNote({
      userId,
      title: dto.title,
      content: dto.content,
      color: dto.color,
      isPinned: dto.is_pinned ?? false,
    });
    await this.store.appendChange({
      userId,
      entityType: 'note',
      entityId: note.id,
      op: 'create',
      version: note.version,
    });
    return note;
  }

  async update(userId: string, id: string, dto: UpdateNoteDto) {
    const note = await this.store.updateNote(id, {
      ...(dto.title !== undefined ? { title: dto.title } : {}),
      ...(dto.content !== undefined ? { content: dto.content } : {}),
      ...(dto.color !== undefined ? { color: dto.color } : {}),
      ...(dto.is_pinned !== undefined ? { isPinned: dto.is_pinned } : {}),
    });
    if (!note) throw new NotFoundException('Note not found');
    await this.store.appendChange({
      userId,
      entityType: 'note',
      entityId: note.id,
      op: 'update',
      version: note.version,
    });
    return note;
  }

  async remove(userId: string, id: string) {
    const note = await this.store.updateNote(id, { isDeleted: true });
    if (!note) throw new NotFoundException('Note not found');
    await this.store.appendChange({
      userId,
      entityType: 'note',
      entityId: note.id,
      op: 'delete',
      version: note.version,
    });
    return note;
  }

  async pin(userId: string, id: string) {
    return this.update(userId, id, { is_pinned: true });
  }

  async archive(userId: string, id: string) {
    const note = await this.store.updateNote(id, { isArchived: true });
    if (!note) throw new NotFoundException('Note not found');
    await this.store.appendChange({
      userId,
      entityType: 'note',
      entityId: note.id,
      op: 'update',
      version: note.version,
    });
    return note;
  }
}
