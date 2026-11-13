import { Module } from '@nestjs/common';
import {
  LocationsController,
  MinLevelsController,
  PackagingController,
  PartnersController,
  ProductsController,
  VehiclesController,
} from './master.controllers';

@Module({
  controllers: [
    ProductsController,
    LocationsController,
    PackagingController,
    PartnersController,
    VehiclesController,
    MinLevelsController,
  ],
})
export class MasterModule {}
