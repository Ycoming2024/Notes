import { IsIn, IsOptional, IsString } from 'class-validator';

export class RegisterDeviceDto {
  @IsIn(['android', 'windows'])
  platform!: 'android' | 'windows';

  @IsOptional()
  @IsString()
  device_name?: string;

  @IsOptional()
  @IsString()
  push_token?: string;
}

export class UpdatePushTokenDto {
  @IsString()
  device_id!: string;

  @IsString()
  push_token!: string;
}
