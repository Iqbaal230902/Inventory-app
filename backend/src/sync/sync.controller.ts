import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpException,
  Post,
  Query,
} from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { ArrayMaxSize, IsArray } from 'class-validator';
import { validate } from 'class-validator';
import { AuthUser, CurrentUser, Roles } from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { PostingService } from '../transactions/posting.service';
import { CreateTransactionDto } from '../transactions/transaction.dto';
import { serializeTrx } from '../transactions/transaction.serializer';

class PushDto {
  @IsArray()
  @ArrayMaxSize(50, { message: 'Maksimal 50 transaksi per kiriman.' })
  transactions!: unknown[];
}

@Controller('sync')
export class SyncController {
  constructor(
    private prisma: PrismaService,
    private posting: PostingService,
    private settings: SettingsService,
  ) {}

  /**
   * Kirim batch transaksi offline. Diproses berurutan (client_created_at),
   * masing-masing atomik. Status per item: ok | duplicate | rejected.
   */
  @Post('push')
  @Roles('owner', 'admin', 'operator')
  @HttpCode(200)
  async push(@CurrentUser() user: AuthUser, @Body() body: PushDto) {
    const items = [...body.transactions].sort((a: any, b: any) =>
      String(a?.client_created_at ?? '').localeCompare(
        String(b?.client_created_at ?? ''),
      ),
    );
    const results: object[] = [];
    for (const raw of items) {
      const uuid = (raw as any)?.client_uuid ?? null;
      const dto = plainToInstance(CreateTransactionDto, raw);
      const errors = await validate(dto, { whitelist: true });
      if (errors.length) {
        const msgs = errors.flatMap((e) =>
          Object.values(e.constraints ?? {}).concat(
            (e.children ?? []).flatMap((c) =>
              (c.children ?? []).flatMap((cc) =>
                Object.values(cc.constraints ?? {}),
              ),
            ),
          ),
        );
        results.push({
          client_uuid: uuid,
          status: 'rejected',
          error: {
            code: 'VALIDATION_ERROR',
            message: `Data tidak valid: ${msgs[0] ?? 'periksa isian'}`,
            details: msgs,
          },
        });
        continue;
      }
      try {
        const r = await this.posting.create(user, dto, 'sync');
        results.push({
          client_uuid: uuid,
          status: r.status,
          warnings: r.warnings,
          transaction: serializeTrx(r.transaction),
        });
      } catch (e) {
        const body =
          e instanceof HttpException ? (e.getResponse() as any) : null;
        results.push({
          client_uuid: uuid,
          status: 'rejected',
          error: body?.error ?? {
            code: 'INTERNAL_ERROR',
            message: 'Gagal memproses transaksi di server.',
          },
        });
      }
    }
    if (user.deviceId) {
      await this.prisma.device.updateMany({
        where: { id: user.deviceId },
        data: { lastSyncAt: new Date() },
      });
    }
    return { server_time: new Date().toISOString(), results };
  }

  /** Delta master data sejak `since` + saldo resmi terkini untuk lokasi user. */
  @Get('pull')
  async pull(@CurrentUser() user: AuthUser, @Query('since') since?: string) {
    const serverTime = new Date();
    const sinceDate = since ? new Date(since) : undefined;
    const changed =
      sinceDate && !isNaN(+sinceDate) ? { updatedAt: { gte: sinceDate } } : {};
    const locFilter =
      user.locationIds === null ? undefined : { in: user.locationIds };

    const [
      products,
      locations,
      packaging,
      partners,
      vehicles,
      minLevels,
      balances,
      settings,
    ] = await Promise.all([
      this.prisma.product.findMany({ where: changed }),
      this.prisma.location.findMany({ where: { ...changed, id: locFilter } }),
      this.prisma.packagingUnit.findMany({ where: changed }),
      this.prisma.partner.findMany({ where: changed }),
      this.prisma.vehicle.findMany({ where: changed }),
      this.prisma.stockMinLevel.findMany({
        where: { ...changed, locationId: locFilter },
      }),
      this.prisma.stockBalance.findMany({ where: { locationId: locFilter } }),
      this.settings.all(),
    ]);
    if (user.deviceId) {
      await this.prisma.device.updateMany({
        where: { id: user.deviceId },
        data: { lastSyncAt: serverTime },
      });
    }
    return {
      server_time: serverTime.toISOString(),
      full: !sinceDate,
      products: products.map((p) => ({
        id: p.id,
        code: p.code,
        name: p.name,
        mesh_size: p.meshSize,
        category: p.category,
        density_ton_m3: p.densityTonM3?.toFixed(3) ?? null,
        sort_order: p.sortOrder,
        is_active: p.isActive,
        updated_at: p.updatedAt.toISOString(),
      })),
      locations: locations.map((l) => ({
        id: l.id,
        code: l.code,
        name: l.name,
        type: l.type,
        address: l.address,
        timezone: l.timezone,
        is_active: l.isActive,
      })),
      packaging_units: packaging.map((p) => ({
        id: p.id,
        name: p.name,
        ton_per_unit: p.tonPerUnit.toFixed(3),
        is_bulk: p.isBulk,
        is_active: p.isActive,
      })),
      partners: partners.map((p) => ({
        id: p.id,
        type: p.type,
        name: p.name,
        phone: p.phone,
        address: p.address,
        is_active: p.isActive,
      })),
      vehicles: vehicles.map((v) => ({
        id: v.id,
        plate_number: v.plateNumber,
        default_driver: v.defaultDriver,
        standard_tare_ton: v.standardTareTon?.toFixed(3) ?? null,
        is_active: v.isActive,
      })),
      min_levels: minLevels.map((m) => ({
        location_id: m.locationId,
        product_id: m.productId,
        min_ton: m.minTon.toFixed(3),
      })),
      balances: balances.map((b) => ({
        location_id: b.locationId,
        product_id: b.productId,
        qty_ton: b.qtyTon.toFixed(3),
        in_transit_ton: b.inTransitTon.toFixed(3),
      })),
      settings,
    };
  }
}
