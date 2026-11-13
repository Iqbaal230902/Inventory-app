import { Module } from '@nestjs/common';
import { PostingService } from './posting.service';
import { TransactionsController } from './transactions.controller';
import { TransactionsService } from './transactions.service';

@Module({
  controllers: [TransactionsController],
  providers: [PostingService, TransactionsService],
  exports: [PostingService, TransactionsService],
})
export class TransactionsModule {}
