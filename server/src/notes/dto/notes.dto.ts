import { IsArray, IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateNoteDto {
  @IsString()
  @MaxLength(200)
  title!: string;

  @IsString()
  content!: string;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsBoolean()
  is_pinned?: boolean;

  @IsOptional()
  @IsArray()
  tags?: string[];
}

export class UpdateNoteDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  content?: string;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsBoolean()
  is_pinned?: boolean;

  @IsOptional()
  @IsArray()
  tags?: string[];
}
