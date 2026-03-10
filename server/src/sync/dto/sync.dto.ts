import { IsArray, IsISO8601, IsIn, IsOptional, IsString, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class ChangeItemDto {
  @IsIn(['note', 'reminder', 'tag'])
  entity_type!: 'note' | 'reminder' | 'tag';

  @IsString()
  entity_id!: string;

  @IsIn(['create', 'update', 'delete'])
  op!: 'create' | 'update' | 'delete';

  @IsString()
  payload!: string;

  @IsISO8601()
  updated_at!: string;
}

export class PushSyncDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChangeItemDto)
  changes!: ChangeItemDto[];
}

export class PullQueryDto {
  @IsOptional()
  @IsISO8601()
  since?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}

export class SyncAckDto {
  @IsISO8601()
  since!: string;
}
