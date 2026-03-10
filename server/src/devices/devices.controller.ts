import { Body, Controller, Headers, Post, Put } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { RegisterDeviceDto, UpdatePushTokenDto } from './dto/devices.dto';

@Controller('devices')
export class DevicesController {
  constructor(private readonly devicesService: DevicesService) {}

  @Post('register')
  register(@Headers('x-user-id') userId: string | undefined, @Body() dto: RegisterDeviceDto) {
    return this.devicesService.register(userId ?? 'demo-user-id', dto);
  }

  @Put('push-token')
  updatePushToken(@Headers('x-user-id') userId: string | undefined, @Body() dto: UpdatePushTokenDto) {
    return this.devicesService.updatePushToken(userId ?? 'demo-user-id', dto);
  }
}
