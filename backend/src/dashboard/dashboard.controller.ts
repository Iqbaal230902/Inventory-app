import { Controller, Get, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../common/auth-user';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private dashboard: DashboardService) {}

  @Get()
  get(
    @CurrentUser() user: AuthUser,
    @Query('location_id') locationId?: string,
  ) {
    return this.dashboard.get(
      user,
      locationId ? Number(locationId) : undefined,
    );
  }
}
