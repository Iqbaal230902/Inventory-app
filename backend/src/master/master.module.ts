import { Module } from '@nestjs/common';
import {
  LocationsController,
  MinLevelsController,
  PackagingController,
  PartnersController,
  ProductsController,
  VehiclesController,
} from './master.controllers';

const CONTROLLERS = [
  ProductsController,
  LocationsController,
  PackagingController,
  PartnersController,
  VehiclesController,
  MinLevelsController,
];

// Controller juga diekspor sebagai provider agar admin panel memakai
// pemetaan data + audit yang sama dengan API.
@Module({
  controllers: CONTROLLERS,
  providers: CONTROLLERS,
  exports: CONTROLLERS,
})
export class MasterModule {}
