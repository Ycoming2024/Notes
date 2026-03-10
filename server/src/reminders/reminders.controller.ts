import { Body, Controller, Delete, Get, Headers, Param, Post, Put, Query } from '@nestjs/common';
import { PaginationQueryDto } from '../common/dto/pagination-query.dto';
import { RemindersService } from './reminders.service';
import { CreateReminderDto, SnoozeReminderDto, UpdateReminderDto } from './dto/reminders.dto';

@Controller('reminders')
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  @Get()
  list(@Headers('x-user-id') userId: string | undefined, @Query() query: PaginationQueryDto) {
    return this.remindersService.list(userId ?? 'demo-user-id', query.updated_after, Number(query.limit ?? '100'));
  }

  @Post()
  create(@Headers('x-user-id') userId: string | undefined, @Body() dto: CreateReminderDto) {
    return this.remindersService.create(userId ?? 'demo-user-id', dto);
  }

  @Put(':id')
  update(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string, @Body() dto: UpdateReminderDto) {
    return this.remindersService.update(userId ?? 'demo-user-id', id, dto);
  }

  @Post(':id/done')
  done(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string) {
    return this.remindersService.done(userId ?? 'demo-user-id', id);
  }

  @Post(':id/snooze')
  snooze(
    @Headers('x-user-id') userId: string | undefined,
    @Param('id') id: string,
    @Body() dto: SnoozeReminderDto,
  ) {
    return this.remindersService.snooze(userId ?? 'demo-user-id', id, dto.minutes);
  }

  @Delete(':id')
  remove(@Headers('x-user-id') userId: string | undefined, @Param('id') id: string) {
    return this.remindersService.remove(userId ?? 'demo-user-id', id);
  }
}
