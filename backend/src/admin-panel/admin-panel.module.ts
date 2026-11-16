import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { DashboardModule } from '../dashboard/dashboard.module';
import { DeliveryNotesModule } from '../delivery-notes/delivery-notes.module';
import { MasterModule } from '../master/master.module';
import { TransactionsModule } from '../transactions/transactions.module';
import { UsersModule } from '../users/users.module';
import { AdminGuard } from './admin-auth';
import { AdminLoginController } from './admin-login.controller';
import { AdminManageController } from './admin-manage.controller';
import { AdminPanelController } from './admin-panel.controller';
import { AdminView } from './admin-view';

/** Admin panel web (Handlebars) di /admin-panel — Owner & Admin. */
@Module({
  imports: [
    AuthModule,
    DashboardModule,
    DeliveryNotesModule,
    MasterModule,
    TransactionsModule,
    UsersModule,
  ],
  controllers: [
    AdminLoginController,
    AdminPanelController,
    AdminManageController,
  ],
  providers: [AdminGuard, AdminView],
})
export class AdminPanelModule {}
