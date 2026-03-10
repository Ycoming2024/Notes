import { Body, Controller, Get, Headers, Post, Query } from '@nestjs/common';
import { SyncService } from './sync.service';
import { PullQueryDto, PushSyncDto, SyncAckDto } from './dto/sync.dto';

@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  push(@Headers('x-user-id') userId: string | undefined, @Body() dto: PushSyncDto) {
    return this.syncService.push(userId ?? 'demo-user-id', dto);
  }

  @Get('pull')
  pull(@Headers('x-user-id') userId: string | undefined, @Query() query: PullQueryDto) {
    return this.syncService.pull(userId ?? 'demo-user-id', query.since, Number(query.limit ?? '500'));
  }

  @Post('ack')
  ack(@Body() dto: SyncAckDto) {
    return this.syncService.ack(dto.since);
  }
}
