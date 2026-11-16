import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AdminPanelModule } from './admin-panel/admin-panel.module';
import { AuditController } from './audit/audit.controller';
import { AuditService } from './audit/audit.service';
import { AuthModule } from './auth/auth.module';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { AllExceptionsFilter } from './common/http-exception.filter';
import { RolesGuard } from './common/roles.guard';
import { SnakeCaseInterceptor } from './common/snake-case.interceptor';
import { DashboardModule } from './dashboard/dashboard.module';
import { DeliveryNotesModule } from './delivery-notes/delivery-notes.module';
import { MasterModule } from './master/master.module';
import { PrismaModule } from './prisma/prisma.module';
import { SettingsController } from './settings/settings.controller';
import { SettingsService } from './settings/settings.service';
import { SyncModule } from './sync/sync.module';
import { TransactionsModule } from './transactions/transactions.module';
import { UsersModule } from './users/users.module';

@Global()
@Module({
  controllers: [AuditController, SettingsController],
  // AuditController juga provider agar admin panel memakai filter akses yang sama.
  providers: [AuditService, SettingsService, AuditController],
  exports: [AuditService, SettingsService, AuditController],
})
class CoreModule {}

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: process.env.NODE_ENV === 'test' ? '.env.test' : '.env',
    }),
    PrismaModule,
    CoreModule,
    AuthModule,
    MasterModule,
    UsersModule,
    TransactionsModule,
    DashboardModule,
    SyncModule,
    DeliveryNotesModule,
    AdminPanelModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_INTERCEPTOR, useClass: SnakeCaseInterceptor },
  ],
})
export class AppModule {}
