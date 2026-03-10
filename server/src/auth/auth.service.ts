import { Injectable } from '@nestjs/common';
import { LocalStoreService } from '../store/local-store.service';

@Injectable()
export class AuthService {
  constructor(private readonly store: LocalStoreService) {}

  async sendEmailCode(email: string) {
    return { ok: true, email };
  }

  async login(email: string) {
    const user = await this.store.upsertUserByEmail(email);
    return {
      access_token: `dev_access_${user.id}`,
      refresh_token: `dev_refresh_${user.id}`,
      user: { id: user.id, email: user.email },
    };
  }
}
