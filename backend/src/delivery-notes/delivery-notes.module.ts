import { Module } from '@nestjs/common';
import { DeliveryNotesController } from './delivery-notes.controller';

// Diekspor sebagai provider agar admin panel bisa merender PDF surat jalan yang sama.
@Module({
  controllers: [DeliveryNotesController],
  providers: [DeliveryNotesController],
  exports: [DeliveryNotesController],
})
export class DeliveryNotesModule {}
