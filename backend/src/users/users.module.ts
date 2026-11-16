import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';

// UsersController juga diekspor sebagai provider agar admin panel memakai
// validasi + audit yang sama dengan API.
@Module({
  controllers: [UsersController],
  providers: [UsersController],
  exports: [UsersController],
})
export class UsersModule {}
