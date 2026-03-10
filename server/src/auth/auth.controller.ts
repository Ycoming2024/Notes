import { Body, Controller, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { EmailLoginDto, SendEmailCodeDto } from './dto/auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('email/send-code')
  sendEmailCode(@Body() dto: SendEmailCodeDto) {
    return this.authService.sendEmailCode(dto.email);
  }

  @Post('email/login')
  login(@Body() dto: EmailLoginDto) {
    return this.authService.login(dto.email);
  }

  @Post('refresh')
  refresh() {
    return { access_token: 'new_mock_access_token' };
  }

  @Post('logout')
  logout() {
    return { ok: true };
  }
}
