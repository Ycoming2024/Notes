import { IsEmail, IsString, Length } from 'class-validator';

export class SendEmailCodeDto {
  @IsEmail()
  email!: string;
}

export class EmailLoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(4, 8)
  code!: string;
}
