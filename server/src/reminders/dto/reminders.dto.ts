import { IsIn, IsISO8601, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateReminderDto {
  @IsString()
  @MaxLength(200)
  title!: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsString()
  note_id?: string;

  @IsISO8601()
  due_at!: string;

  @IsIn(['none', 'daily', 'workday', 'weekly', 'custom'])
  repeat_rule!: 'none' | 'daily' | 'workday' | 'weekly' | 'custom';
}

export class UpdateReminderDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  body?: string;

  @IsOptional()
  @IsISO8601()
  due_at?: string;

  @IsOptional()
  @IsIn(['none', 'daily', 'workday', 'weekly', 'custom'])
  repeat_rule?: 'none' | 'daily' | 'workday' | 'weekly' | 'custom';
}

export class SnoozeReminderDto {
  @IsIn([5, 10, 30])
  minutes!: 5 | 10 | 30;
}
