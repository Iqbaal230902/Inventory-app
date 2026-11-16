import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import {
  AuthUser,
  canAccessLocation,
  CurrentUser,
  Roles,
} from '../common/auth-user';
import { dec } from '../common/decimal';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePlate } from '../transactions/posting.service';
import {
  LocationDto,
  MinLevelDto,
  PackagingDto,
  PartnerDto,
  ProductDto,
  VehicleDto,
} from './master.dto';

const active = (all?: string) => (all === '1' ? {} : { isActive: true });

abstract class Base {
  constructor(
    protected prisma: PrismaService,
    protected audit: AuditService,
  ) {}
  protected log(
    user: AuthUser,
    action: string,
    entity: string,
    id: number,
    oldValues?: unknown,
    newValues?: unknown,
  ) {
    return this.audit.log({
      user,
      action,
      entity,
      entityId: id,
      oldValues,
      newValues,
    });
  }
}

@Controller('products')
export class ProductsController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  private data(d: ProductDto) {
    return {
      code: d.code.toUpperCase(),
      name: d.name.trim(),
      meshSize: d.mesh_size || null,
      category: d.category,
      densityTonM3: d.density_ton_m3
        ? dec(d.density_ton_m3).toFixed(3)
        : undefined,
      sortOrder: d.sort_order,
      isActive: d.is_active,
    };
  }

  @Get() list(@Query('all') all?: string) {
    return this.prisma.product.findMany({
      where: active(all),
      orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
    });
  }

  @Post()
  @Roles('owner', 'admin')
  async create(@CurrentUser() u: AuthUser, @Body() d: ProductDto) {
    const r = await this.prisma.product.create({ data: this.data(d) });
    await this.log(u, 'create', 'product', r.id, null, r);
    return r;
  }

  @Put(':id')
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: ProductDto,
  ) {
    const old = await this.prisma.product.findUniqueOrThrow({ where: { id } });
    const r = await this.prisma.product.update({
      where: { id },
      data: this.data(d),
    });
    await this.log(u, 'update', 'product', id, old, r);
    return r;
  }

  @Delete(':id')
  @Roles('owner', 'admin')
  async remove(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const r = await this.prisma.product.update({
      where: { id },
      data: { isActive: false },
    });
    await this.log(u, 'deactivate', 'product', id);
    return r;
  }
}

@Controller('locations')
export class LocationsController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  private data(d: LocationDto) {
    return {
      code: d.code.toUpperCase(),
      name: d.name.trim(),
      type: d.type,
      address: d.address ?? null,
      timezone: d.timezone,
      isActive: d.is_active,
    };
  }

  @Get() list(@CurrentUser() u: AuthUser, @Query('all') all?: string) {
    return this.prisma.location.findMany({
      where: {
        ...active(all),
        id: u.locationIds === null ? undefined : { in: u.locationIds },
      },
      orderBy: { code: 'asc' },
    });
  }

  // Gudang/lokasi baru hanya bisa dibuat & diubah Owner (super admin).
  // Admin/Operator diberi akses lewat Manajemen User.
  @Post()
  @Roles('owner')
  async create(@CurrentUser() u: AuthUser, @Body() d: LocationDto) {
    const r = await this.prisma.location.create({ data: this.data(d) });
    await this.log(u, 'create', 'location', r.id, null, r);
    return r;
  }

  @Put(':id')
  @Roles('owner')
  async update(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: LocationDto,
  ) {
    const old = await this.prisma.location.findUniqueOrThrow({ where: { id } });
    const r = await this.prisma.location.update({
      where: { id },
      data: this.data(d),
    });
    await this.log(u, 'update', 'location', id, old, r);
    return r;
  }

  @Delete(':id')
  @Roles('owner')
  async remove(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const r = await this.prisma.location.update({
      where: { id },
      data: { isActive: false },
    });
    await this.log(u, 'deactivate', 'location', id);
    return r;
  }
}

@Controller('packaging-units')
export class PackagingController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  private data(d: PackagingDto) {
    return {
      name: d.name.trim(),
      tonPerUnit: dec(d.ton_per_unit).toFixed(3),
      isBulk: d.is_bulk,
      isActive: d.is_active,
    };
  }

  @Get() list(@Query('all') all?: string) {
    return this.prisma.packagingUnit.findMany({
      where: active(all),
      orderBy: { id: 'asc' },
    });
  }

  @Post()
  @Roles('owner', 'admin')
  async create(@CurrentUser() u: AuthUser, @Body() d: PackagingDto) {
    if (dec(d.ton_per_unit).lte(0))
      throw AppError.validation('Ton per kemasan harus > 0.');
    const r = await this.prisma.packagingUnit.create({ data: this.data(d) });
    await this.log(u, 'create', 'packaging_unit', r.id, null, r);
    return r;
  }

  @Put(':id')
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: PackagingDto,
  ) {
    if (dec(d.ton_per_unit).lte(0))
      throw AppError.validation('Ton per kemasan harus > 0.');
    const old = await this.prisma.packagingUnit.findUniqueOrThrow({
      where: { id },
    });
    const r = await this.prisma.packagingUnit.update({
      where: { id },
      data: this.data(d),
    });
    await this.log(u, 'update', 'packaging_unit', id, old, r);
    return r;
  }

  @Delete(':id')
  @Roles('owner', 'admin')
  async remove(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const r = await this.prisma.packagingUnit.update({
      where: { id },
      data: { isActive: false },
    });
    await this.log(u, 'deactivate', 'packaging_unit', id);
    return r;
  }
}

@Controller('partners')
export class PartnersController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  private data(d: PartnerDto) {
    return {
      type: d.type,
      name: d.name.trim(),
      phone: d.phone ?? null,
      address: d.address ?? null,
      isActive: d.is_active,
    };
  }

  @Get() list(
    @Query('all') all?: string,
    @Query('type') type?: string,
    @Query('q') q?: string,
  ) {
    return this.prisma.partner.findMany({
      where: {
        ...active(all),
        type: type
          ? { in: [type as 'customer' | 'supplier', 'both'] }
          : undefined,
        name: q ? { contains: q } : undefined,
      },
      orderBy: { name: 'asc' },
    });
  }

  @Post()
  @Roles('owner', 'admin')
  async create(@CurrentUser() u: AuthUser, @Body() d: PartnerDto) {
    const r = await this.prisma.partner.create({ data: this.data(d) });
    await this.log(u, 'create', 'partner', r.id, null, r);
    return r;
  }

  @Put(':id')
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: PartnerDto,
  ) {
    const old = await this.prisma.partner.findUniqueOrThrow({ where: { id } });
    const r = await this.prisma.partner.update({
      where: { id },
      data: this.data(d),
    });
    await this.log(u, 'update', 'partner', id, old, r);
    return r;
  }

  @Delete(':id')
  @Roles('owner', 'admin')
  async remove(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const r = await this.prisma.partner.update({
      where: { id },
      data: { isActive: false },
    });
    await this.log(u, 'deactivate', 'partner', id);
    return r;
  }
}

@Controller('vehicles')
export class VehiclesController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  private data(d: VehicleDto) {
    const plate = normalizePlate(d.plate_number);
    if (!plate) throw AppError.validation('No. Polisi tidak valid.');
    return {
      plateNumber: plate,
      defaultDriver: d.default_driver ?? null,
      standardTareTon: d.standard_tare_ton
        ? dec(d.standard_tare_ton).toFixed(3)
        : null,
      isActive: d.is_active,
    };
  }

  @Get() list(@Query('all') all?: string) {
    return this.prisma.vehicle.findMany({
      where: active(all),
      orderBy: { plateNumber: 'asc' },
    });
  }

  @Post()
  @Roles('owner', 'admin')
  async create(@CurrentUser() u: AuthUser, @Body() d: VehicleDto) {
    const r = await this.prisma.vehicle.create({ data: this.data(d) });
    await this.log(u, 'create', 'vehicle', r.id, null, r);
    return r;
  }

  @Put(':id')
  @Roles('owner', 'admin')
  async update(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: VehicleDto,
  ) {
    const old = await this.prisma.vehicle.findUniqueOrThrow({ where: { id } });
    const r = await this.prisma.vehicle.update({
      where: { id },
      data: this.data(d),
    });
    await this.log(u, 'update', 'vehicle', id, old, r);
    return r;
  }

  @Delete(':id')
  @Roles('owner', 'admin')
  async remove(
    @CurrentUser() u: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const r = await this.prisma.vehicle.update({
      where: { id },
      data: { isActive: false },
    });
    await this.log(u, 'deactivate', 'vehicle', id);
    return r;
  }
}

@Controller('min-levels')
export class MinLevelsController extends Base {
  constructor(prisma: PrismaService, audit: AuditService) {
    super(prisma, audit);
  }

  @Get() list(
    @CurrentUser() u: AuthUser,
    @Query('location_id') locationId?: string,
  ) {
    const loc = locationId ? Number(locationId) : undefined;
    if (loc && !canAccessLocation(u, loc)) throw AppError.forbidden();
    return this.prisma.stockMinLevel.findMany({
      where: {
        locationId:
          loc ?? (u.locationIds === null ? undefined : { in: u.locationIds }),
      },
    });
  }

  @Put()
  @Roles('owner', 'admin')
  async upsert(@CurrentUser() u: AuthUser, @Body() d: MinLevelDto) {
    if (!canAccessLocation(u, d.location_id)) throw AppError.forbidden();
    const key = {
      locationId_productId: {
        locationId: d.location_id,
        productId: d.product_id,
      },
    };
    const old = await this.prisma.stockMinLevel.findUnique({ where: key });
    const minTon = dec(d.min_ton).toFixed(3);
    const r = await this.prisma.stockMinLevel.upsert({
      where: key,
      update: { minTon },
      create: { locationId: d.location_id, productId: d.product_id, minTon },
    });
    await this.log(u, 'update', 'min_level', d.product_id, old, r);
    return r;
  }
}
