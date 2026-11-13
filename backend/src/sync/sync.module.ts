import { Module } from '@nestjs/common';
import { TransactionsModule } from '../transactions/transactions.module';
import { SyncController } from './sync.controller';

@Module({ imports: [TransactionsModule], controllers: [SyncController] })
export class SyncModule {}
