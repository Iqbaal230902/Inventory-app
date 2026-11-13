import { Body, Controller, Get, Put } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { AuthUser, CurrentUser, Roles } from '../common/auth-user';
import { SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(
    private settings: SettingsService,
    private audit: AuditService,
  ) {}

  @Get()
  all() {
    return this.settings.all();
  }

  @Put()
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() user: AuthUser,
    @Body() body: Record<string, string>,
  ) {
    const before = await this.settings.all();
    const after = await this.settings.update(body ?? {});
    await this.audit.log({
      user,
      action: 'update',
      entity: 'settings',
      oldValues: before,
      newValues: after,
    });
    return after;
  }
}
