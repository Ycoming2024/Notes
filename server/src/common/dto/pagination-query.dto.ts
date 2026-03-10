import { IsOptional, IsString } from 'class-validator';

export class PaginationQueryDto {
  @IsOptional()
  @IsString()
  updated_after?: string;

  @IsOptional()
  @IsString()
  limit?: string;
}
