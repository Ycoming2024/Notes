import { Body, Controller, Delete, Get, Headers, Param, Post, Put, Query } from '@nestjs/common';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto';
import { NotesService } from './notes.service';
import { CreateNoteDto, UpdateNoteDto } from './dto/notes.dto';

@Controller('notes')
export class NotesController {
  constructor(private readonly notesService: NotesService) {}

  @Get()
  list(@Headers('x-user-id') userId: string | undefined, @Query() query: PaginationQueryDto) {
    return this.notesService.list(userId ?? 'demo-user-id', query.updated_after, Number(query.limit ?? '100'));
  }

  @Post()
  create(@Headers('x-user-id') userId: string | undefined, @Body() dto: CreateNoteDto) {
    return this.notesService.create(userId ?? 'demo-user-id', dto);
  }

  @Put(':id')
  update(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string, @Body() dto: UpdateNoteDto) {
    return this.notesService.update(userId ?? 'demo-user-id', id, dto);
  }

  @Delete(':id')
  remove(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string) {
    return this.notesService.remove(userId ?? 'demo-user-id', id);
  }

  @Post(':id/pin')
  pin(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string) {
    return this.notesService.pin(userId ?? 'demo-user-id', id);
  }

  @Post(':id/archive')
  archive(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string) {
    return this.notesService.archive(userId ?? 'demo-user-id', id);
  }
}
