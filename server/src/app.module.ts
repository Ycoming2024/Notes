import { Module } from '@nestjs/common';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { DevicesController } from './devices/devices.controller';
import { DevicesService } from './devices/devices.service';
import { NotesController } from './notes/notes.controller';
import { NotesService } from './notes/notes.service';
import { RemindersController } from './reminders/reminders.controller';
import { RemindersService } from './reminders/reminders.service';
import { LocalStoreService } from './store/local-store.service';
import { SyncController } from './sync/sync.controller';
import { SyncService } from './sync/sync.service';

@Module({
  imports: [],
  controllers: [AuthController, DevicesController, NotesController, RemindersController, SyncController],
  providers: [LocalStoreService, AuthService, DevicesService, NotesService, RemindersService, SyncService],
})
export class AppModule {}
