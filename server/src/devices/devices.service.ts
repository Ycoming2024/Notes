import { Injectable } from '@nestjs/common';
import { LocalStoreService } from '../store/local-store.service';
import { RegisterDeviceDto, UpdatePushTokenDto } from './dto/devices.dto';

@Injectable()
export class DevicesService {
  constructor(private readonly store: LocalStoreService) {}

  async register(userId: string, dto: RegisterDeviceDto) {
    await this.store.ensureUser(userId);
    return this.store.createDevice({
      userId,
      platform: dto.platform,
      deviceName: dto.device_name,
      pushToken: dto.push_token,
      lastSeenAt: new Date().toISOString(),
    });
  }

  async updatePushToken(userId: string, dto: UpdatePushTokenDto) {
    await this.store.ensureUser(userId);
    await this.store.updatePushToken(userId, dto.device_id, dto.push_token);
    return { ok: true };
  }
}
