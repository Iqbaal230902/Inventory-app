import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Req,
  Res,
  UploadedFile,
  UseFilters,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Prisma } from '@prisma/client';
import { Response } from 'express';
import { memoryStorage } from 'multer';
import { AuditController } from '../audit/audit.controller';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import { AuthUser, locationScope, Public } from '../common/auth-user';
import { dec } from '../common/decimal';
import {
  LocationDto,
  MinLevelDto,
  PackagingDto,
  PartnerDto,
  ProductDto,
  VehicleDto,
} from '../master/master.dto';
import {
  LocationsController,
  MinLevelsController,
  PackagingController,
  PartnersController,
  ProductsController,
  VehiclesController,
} from '../master/master.controllers';
import { PrismaService } from '../prisma/prisma.service';
import {
  DEFAULT_SETTINGS,
  SettingsService,
} from '../settings/settings.service';
import { UserDto, UsersController } from '../users/users.controller';
import {
  ADMIN_BASE,
  AdminExceptionFilter,
  AdminGuard,
  AdminRequest,
  OwnerOnly,
  setFlash,
} from './admin-auth';
import {
  AdminView,
  bool,
  intList,
  opt,
  validated,
  withQuery,
} from './admin-view';
import { ACTION_LABEL, ROLE_LABEL, fmtDateTime, str } from './view-engine';

type Field = {
  name: string;
  label: string;
  type?: 'text' | 'select' | 'checkbox' | 'textarea' | 'number';
  options?: { value: string; label: string }[];
  required?: boolean;
  help?: string;
  readonlyOnEdit?: boolean;
};

interface CrudCtrl {
  create(u: AuthUser, d: unknown): Promise<{ id: number }>;
  update(u: AuthUser, id: number, d: unknown): Promise<unknown>;
}

interface EntitySpec {
  key: string;
  title: string;
  singular: string;
  ownerOnly?: boolean;
  canCreate: boolean;
  note?: string;
  columns: string[];
  fields: Field[];
  dto: new () => object;
  find(prisma: PrismaService, user: AuthUser): Promise<any[]>;
  findOne(prisma: PrismaService, id: number): Promise<any>;
  row(r: any): unknown[];
  /** Nilai record → nilai form (nama field = nama DTO). */
  toForm(r: any): Record<string, unknown>;
  /** Body form → objek DTO (sebelum validasi). */
  fromForm(b: Record<string, unknown>): Record<string, unknown>;
}

const labelsOf = (fields: Field[]) =>
  Object.fromEntries(fields.map((f) => [f.name, f.label]));
const yesNo = (v: boolean) => (v ? 'Aktif' : 'Nonaktif');
const CATEGORY = [
  { value: 'finished', label: 'Produk jadi' },
  { value: 'raw', label: 'Bahan baku' },
  { value: 'byproduct', label: 'Produk sampingan' },
];
const LOC_TYPE = [
  { value: 'gudang', label: 'Gudang' },
  { value: 'tambang', label: 'Tambang' },
  { value: 'pabrik', label: 'Pabrik' },
  { value: 'stockpile', label: 'Stockpile' },
];
const TZ = [
  { value: 'Asia/Jakarta', label: 'WIB (Asia/Jakarta)' },
  { value: 'Asia/Makassar', label: 'WITA (Asia/Makassar)' },
  { value: 'Asia/Jayapura', label: 'WIT (Asia/Jayapura)' },
];
const PARTNER_TYPE = [
  { value: 'customer', label: 'Pelanggan' },
  { value: 'supplier', label: 'Supplier' },
  { value: 'both', label: 'Pelanggan & Supplier' },
];
const label = (list: { value: string; label: string }[], v: string) =>
  list.find((x) => x.value === v)?.label ?? v;

const SPECS: EntitySpec[] = [
  {
    key: 'products',
    title: 'Produk (Jenis Pasir)',
    singular: 'Produk',
    canCreate: false,
    note: 'Jenis pasir dibatasi 4 mesh (4/8, 8/14, 14/20, 20/40). Produk bisa diubah atau dinonaktifkan, tidak ditambah dari sini.',
    columns: ['Kode', 'Nama', 'Mesh', 'Kategori', 'Urutan', 'Status'],
    fields: [
      { name: 'code', label: 'Kode', required: true, readonlyOnEdit: true },
      { name: 'name', label: 'Nama', required: true },
      { name: 'mesh_size', label: 'Ukuran mesh', help: 'mis. 8/14' },
      {
        name: 'category',
        label: 'Kategori',
        type: 'select',
        options: CATEGORY,
      },
      { name: 'density_ton_m3', label: 'Densitas (ton/m³)', help: 'mis. 1,6' },
      { name: 'sort_order', label: 'Urutan tampil', type: 'number' },
      { name: 'is_active', label: 'Aktif', type: 'checkbox' },
    ],
    dto: ProductDto,
    find: (p) =>
      p.product.findMany({ orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }] }),
    findOne: (p, id) => p.product.findUniqueOrThrow({ where: { id } }),
    row: (r) => [
      r.code,
      r.name,
      r.meshSize ?? '',
      label(CATEGORY, r.category),
      r.sortOrder,
      yesNo(r.isActive),
    ],
    toForm: (r) => ({
      code: r.code,
      name: r.name,
      mesh_size: r.meshSize,
      category: r.category,
      density_ton_m3: r.densityTonM3?.toString().replace('.', ','),
      sort_order: r.sortOrder,
      is_active: r.isActive,
    }),
    fromForm: (b) => ({
      code: b.code,
      name: b.name,
      mesh_size: opt(b.mesh_size) ?? null,
      category: b.category,
      density_ton_m3: opt(b.density_ton_m3),
      sort_order: opt(b.sort_order) ? Number(b.sort_order) : undefined,
      is_active: bool(b.is_active),
    }),
  },
  {
    key: 'locations',
    title: 'Gudang / Lokasi',
    singular: 'Gudang',
    ownerOnly: true,
    canCreate: true,
    columns: ['Kode', 'Nama', 'Tipe', 'Zona waktu', 'Alamat', 'Status'],
    fields: [
      {
        name: 'code',
        label: 'Kode',
        required: true,
        help: 'Huruf/angka, dipakai di nomor SJ (mis. GDA)',
      },
      { name: 'name', label: 'Nama', required: true },
      { name: 'type', label: 'Tipe', type: 'select', options: LOC_TYPE },
      { name: 'timezone', label: 'Zona waktu', type: 'select', options: TZ },
      { name: 'address', label: 'Alamat', type: 'textarea' },
      { name: 'is_active', label: 'Aktif', type: 'checkbox' },
    ],
    dto: LocationDto,
    find: (p) => p.location.findMany({ orderBy: { code: 'asc' } }),
    findOne: (p, id) => p.location.findUniqueOrThrow({ where: { id } }),
    row: (r) => [
      r.code,
      r.name,
      label(LOC_TYPE, r.type),
      r.timezone,
      r.address ?? '',
      yesNo(r.isActive),
    ],
    toForm: (r) => ({
      code: r.code,
      name: r.name,
      type: r.type,
      timezone: r.timezone,
      address: r.address,
      is_active: r.isActive,
    }),
    fromForm: (b) => ({
      code: b.code,
      name: b.name,
      type: b.type,
      timezone: opt(b.timezone),
      address: opt(b.address) ?? null,
      is_active: bool(b.is_active),
    }),
  },
  {
    key: 'packaging',
    title: 'Kemasan',
    singular: 'Kemasan',
    canCreate: true,
    columns: ['Nama', 'Ton / kemasan', 'Curah', 'Status'],
    fields: [
      {
        name: 'name',
        label: 'Nama',
        required: true,
        help: 'mis. Jumbo bag 1 ton',
      },
      {
        name: 'ton_per_unit',
        label: 'Ton per kemasan',
        required: true,
        help: 'mis. 1 atau 0,05',
      },
      { name: 'is_bulk', label: 'Curah (tanpa kemasan)', type: 'checkbox' },
      { name: 'is_active', label: 'Aktif', type: 'checkbox' },
    ],
    dto: PackagingDto,
    find: (p) => p.packagingUnit.findMany({ orderBy: { id: 'asc' } }),
    findOne: (p, id) => p.packagingUnit.findUniqueOrThrow({ where: { id } }),
    row: (r) => [
      r.name,
      dec(r.tonPerUnit).toFixed(3).replace('.', ','),
      r.isBulk ? 'Ya' : '',
      yesNo(r.isActive),
    ],
    toForm: (r) => ({
      name: r.name,
      ton_per_unit: r.tonPerUnit?.toString().replace('.', ','),
      is_bulk: r.isBulk,
      is_active: r.isActive,
    }),
    fromForm: (b) => ({
      name: b.name,
      ton_per_unit: b.ton_per_unit,
      is_bulk: bool(b.is_bulk),
      is_active: bool(b.is_active),
    }),
  },
  {
    key: 'partners',
    title: 'Pelanggan & Supplier',
    singular: 'Pelanggan / Supplier',
    canCreate: true,
    columns: ['Nama', 'Tipe', 'Telepon', 'Alamat', 'Status'],
    fields: [
      { name: 'name', label: 'Nama', required: true },
      { name: 'type', label: 'Tipe', type: 'select', options: PARTNER_TYPE },
      { name: 'phone', label: 'Telepon' },
      { name: 'address', label: 'Alamat', type: 'textarea' },
      { name: 'is_active', label: 'Aktif', type: 'checkbox' },
    ],
    dto: PartnerDto,
    find: (p) => p.partner.findMany({ orderBy: { name: 'asc' } }),
    findOne: (p, id) => p.partner.findUniqueOrThrow({ where: { id } }),
    row: (r) => [
      r.name,
      label(PARTNER_TYPE, r.type),
      r.phone ?? '',
      r.address ?? '',
      yesNo(r.isActive),
    ],
    toForm: (r) => ({
      name: r.name,
      type: r.type,
      phone: r.phone,
      address: r.address,
      is_active: r.isActive,
    }),
    fromForm: (b) => ({
      name: b.name,
      type: b.type,
      phone: opt(b.phone) ?? null,
      address: opt(b.address) ?? null,
      is_active: bool(b.is_active),
    }),
  },
  {
    key: 'vehicles',
    title: 'Kendaraan',
    singular: 'Kendaraan',
    canCreate: true,
    columns: ['No. Polisi', 'Sopir default', 'Tara standar (ton)', 'Status'],
    fields: [
      {
        name: 'plate_number',
        label: 'No. Polisi',
        required: true,
        help: 'mis. B 1234 XYZ',
      },
      { name: 'default_driver', label: 'Sopir default' },
      {
        name: 'standard_tare_ton',
        label: 'Tara standar (ton)',
        help: 'Berat truk kosong, mis. 7,5',
      },
      { name: 'is_active', label: 'Aktif', type: 'checkbox' },
    ],
    dto: VehicleDto,
    find: (p) => p.vehicle.findMany({ orderBy: { plateNumber: 'asc' } }),
    findOne: (p, id) => p.vehicle.findUniqueOrThrow({ where: { id } }),
    row: (r) => [
      r.plateNumber,
      r.defaultDriver ?? '',
      r.standardTareTon
        ? dec(r.standardTareTon).toFixed(3).replace('.', ',')
        : '',
      yesNo(r.isActive),
    ],
    toForm: (r) => ({
      plate_number: r.plateNumber,
      default_driver: r.defaultDriver,
      standard_tare_ton: r.standardTareTon?.toString().replace('.', ','),
      is_active: r.isActive,
    }),
    fromForm: (b) => ({
      plate_number: b.plate_number,
      default_driver: opt(b.default_driver) ?? null,
      standard_tare_ton: opt(b.standard_tare_ton) ?? null,
      is_active: bool(b.is_active),
    }),
  },
];

const SETTING_FIELDS: Field[] = [
  { name: 'company_name', label: 'Nama perusahaan', required: true },
  { name: 'company_address', label: 'Alamat', type: 'textarea' },
  { name: 'company_phone', label: 'Telepon' },
  {
    name: 'max_net_ton_per_trx',
    label: 'Batas wajar netto per truk (ton)',
    help: 'Transaksi di atas angka ini diberi peringatan.',
  },
  {
    name: 'duplicate_plate_window_min',
    label: 'Jendela cek input ganda (menit)',
    help: 'Peringatan bila truk yang sama keluar lagi dalam rentang ini.',
  },
  {
    name: 'lock_after_days',
    label: 'Kunci transaksi setelah (hari)',
    help: '1 = transaksi terkunci mulai H+1.',
  },
  { name: 'shrink_tolerance_pct', label: 'Toleransi susut (%)' },
  { name: 'production_loss_threshold_pct', label: 'Ambang loss produksi (%)' },
];

/** Admin panel: data master, stok minimum, user, audit, pengaturan. */
@Public()
@Controller('admin-panel')
@UseGuards(AdminGuard)
@UseFilters(AdminExceptionFilter)
export class AdminManageController {
  private ctrls: Record<string, CrudCtrl>;

  constructor(
    private view: AdminView,
    private prisma: PrismaService,
    private settings: SettingsService,
    private audit: AuditService,
    private auditLogs: AuditController,
    private users: UsersController,
    private minLevels: MinLevelsController,
    products: ProductsController,
    locations: LocationsController,
    packaging: PackagingController,
    partners: PartnersController,
    vehicles: VehiclesController,
  ) {
    this.ctrls = {
      products,
      locations,
      packaging,
      partners,
      vehicles,
    };
  }

  private spec(req: AdminRequest, key: string) {
    const s = SPECS.find((x) => x.key === key);
    if (!s) throw AppError.notFound('Halaman tidak ditemukan.');
    if (s.ownerOnly && req.user.role !== 'owner')
      throw AppError.forbidden('Halaman ini hanya untuk Owner.');
    return s;
  }

  // ───────────────────────── Data master ─────────────────────────

  @Get('master')
  master(@Req() req: AdminRequest, @Res() res: Response) {
    return res.redirect(`${ADMIN_BASE}/master/partners`);
  }

  @Get('master/:entity')
  async masterList(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('entity') entity: string,
  ) {
    const s = this.spec(req, entity);
    const rows = await s.find(this.prisma, req.user);
    return this.view.render(req, res, 'master-list', 'master', {
      title: s.title,
      s,
      tabs: this.tabs(req, s.key),
      rows: rows.map((r) => ({
        id: r.id,
        cells: s.row(r),
        inactive: r.isActive === false,
      })),
    });
  }

  private tabs(req: AdminRequest, active: string) {
    return SPECS.filter((x) => !x.ownerOnly || req.user.role === 'owner').map(
      (x) => ({ key: x.key, title: x.title, active: x.key === active }),
    );
  }

  private formFields(
    s: EntitySpec,
    values: Record<string, unknown>,
    edit: boolean,
  ) {
    return s.fields.map((f) => ({
      ...f,
      type: f.type ?? 'text',
      value: values[f.name] ?? '',
      readonly: edit && f.readonlyOnEdit,
      options: f.options?.map((o) => ({
        ...o,
        selected: str(values[f.name]) === o.value,
      })),
    }));
  }

  @Get('master/:entity/new')
  masterNew(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('entity') entity: string,
  ) {
    const s = this.spec(req, entity);
    if (!s.canCreate) throw AppError.forbidden(s.note);
    return this.view.render(req, res, 'master-form', 'master', {
      title: `Tambah ${s.singular}`,
      s,
      action: `${ADMIN_BASE}/master/${s.key}`,
      fields: this.formFields(s, { is_active: true }, false),
    });
  }

  @Get('master/:entity/:id')
  async masterEdit(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('entity') entity: string,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const s = this.spec(req, entity);
    const r = await s.findOne(this.prisma, id);
    return this.view.render(req, res, 'master-form', 'master', {
      title: `Ubah ${s.singular}`,
      s,
      edit: true,
      action: `${ADMIN_BASE}/master/${s.key}/${id}`,
      fields: this.formFields(s, s.toForm(r), true),
    });
  }

  @Post('master/:entity')
  async masterCreate(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('entity') entity: string,
    @Body() body: Record<string, unknown>,
  ) {
    const s = this.spec(req, entity);
    if (!s.canCreate) throw AppError.forbidden(s.note);
    const dto = await validated(s.dto, s.fromForm(body), labelsOf(s.fields));
    await this.ctrls[s.key].create(req.user, dto);
    setFlash(req, res, 'ok', `${s.singular} berhasil ditambahkan.`);
    return res.redirect(`${ADMIN_BASE}/master/${s.key}`);
  }

  @Post('master/:entity/:id')
  async masterUpdate(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('entity') entity: string,
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Record<string, unknown>,
  ) {
    const s = this.spec(req, entity);
    const values = s.fromForm(body);
    // Field yang tidak boleh diubah (mis. kode produk) tetap memakai nilai lama.
    const ro = s.fields.filter((f) => f.readonlyOnEdit).map((f) => f.name);
    if (ro.length) {
      const old = s.toForm(await s.findOne(this.prisma, id));
      for (const k of ro) values[k] = old[k];
    }
    const dto = await validated(s.dto, values, labelsOf(s.fields));
    await this.ctrls[s.key].update(req.user, id, dto);
    setFlash(req, res, 'ok', `${s.singular} berhasil disimpan.`);
    return res.redirect(`${ADMIN_BASE}/master/${s.key}`);
  }

  // ───────────────────────── Stok minimum ─────────────────────────

  @Get('min-levels')
  async minLevelPage(@Req() req: AdminRequest, @Res() res: Response) {
    const [locations, products, mins] = await Promise.all([
      this.prisma.location.findMany({
        where: {
          isActive: true,
          id: locationScope(req.user) as Prisma.IntFilter | undefined,
        },
        orderBy: { code: 'asc' },
      }),
      this.prisma.product.findMany({
        where: { isActive: true },
        orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
      }),
      this.prisma.stockMinLevel.findMany(),
    ]);
    return this.view.render(req, res, 'min-levels', 'minLevels', {
      title: 'Stok Minimum',
      locations,
      products: products.map((p) => ({
        name: p.name,
        cells: locations.map((l) => {
          const m = mins.find(
            (x) => x.locationId === l.id && x.productId === p.id,
          );
          return {
            name: `min_${l.id}_${p.id}`,
            value: m ? dec(m.minTon).toFixed(3).replace('.', ',') : '',
          };
        }),
      })),
    });
  }

  @Post('min-levels')
  async minLevelSave(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Body() body: Record<string, unknown>,
  ) {
    const mins = await this.prisma.stockMinLevel.findMany();
    let changed = 0;
    for (const [k, raw] of Object.entries(body)) {
      const m = /^min_(\d+)_(\d+)$/.exec(k);
      if (!m) continue;
      const [locationId, productId] = [Number(m[1]), Number(m[2])];
      const v = str(raw).trim() || '0';
      const cur = mins.find(
        (x) => x.locationId === locationId && x.productId === productId,
      );
      const dto = await validated(
        MinLevelDto,
        { location_id: locationId, product_id: productId, min_ton: v },
        { min_ton: 'Stok minimum' },
      );
      if (dec(cur?.minTon ?? 0).eq(dec(v))) continue;
      await this.minLevels.upsert(req.user, dto);
      changed++;
    }
    setFlash(
      req,
      res,
      'ok',
      changed ? `${changed} stok minimum disimpan.` : 'Tidak ada perubahan.',
    );
    return res.redirect(`${ADMIN_BASE}/min-levels`);
  }

  // ───────────────────────── User (Owner) ─────────────────────────

  @Get('users')
  @OwnerOnly()
  async userList(@Req() req: AdminRequest, @Res() res: Response) {
    const users = await this.users.list();
    const now = new Date();
    return this.view.render(req, res, 'users', 'users', {
      title: 'Manajemen User',
      users: users.map((u) => ({
        ...u,
        locked: u.lockedUntil && new Date(u.lockedUntil) > now,
        locationNames: u.locations
          .map((l: { name: string }) => l.name)
          .join(', '),
        lastLogin: fmtDateTime(u.lastLoginAt),
      })),
    });
  }

  private async userForm(
    req: AdminRequest,
    res: Response,
    u: Record<string, any> | null,
  ) {
    const locations = await this.prisma.location.findMany({
      where: { isActive: true },
      orderBy: { code: 'asc' },
    });
    const selected: number[] =
      u?.locations?.map((l: { id: number }) => l.id) ?? [];
    return this.view.render(req, res, 'user-form', 'users', {
      title: u ? `Ubah User: ${u.name}` : 'Tambah User',
      u: u ?? { isActive: true, role: 'operator' },
      edit: !!u,
      self: u?.id === req.user.id,
      action: u ? `${ADMIN_BASE}/users/${u.id}` : `${ADMIN_BASE}/users`,
      roles: Object.entries(ROLE_LABEL).map(([value, label]) => ({
        value,
        label,
        selected: (u?.role ?? 'operator') === value,
      })),
      locations: locations.map((l) => ({
        ...l,
        checked: selected.includes(l.id),
      })),
    });
  }

  @Get('users/new')
  @OwnerOnly()
  userNew(@Req() req: AdminRequest, @Res() res: Response) {
    return this.userForm(req, res, null);
  }

  @Get('users/:id')
  @OwnerOnly()
  async userEdit(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const u = (await this.users.list()).find((x) => x.id === id);
    if (!u) throw AppError.notFound('User tidak ditemukan.');
    return this.userForm(req, res, u);
  }

  private userDto(b: Record<string, unknown>) {
    return validated(
      UserDto,
      {
        name: b.name,
        username: b.username,
        email: opt(b.email) ?? null,
        role: b.role,
        password: opt(b.password),
        location_ids: intList(b.location_ids),
        is_active: bool(b.is_active),
      },
      {
        name: 'Nama',
        username: 'Username',
        email: 'Email',
        role: 'Role',
        password: 'Password',
        location_ids: 'Lokasi',
      },
    );
  }

  @Post('users')
  @OwnerOnly()
  async userCreate(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Body() body: Record<string, unknown>,
  ) {
    await this.users.create(req.user, await this.userDto(body));
    setFlash(req, res, 'ok', 'User berhasil ditambahkan.');
    return res.redirect(`${ADMIN_BASE}/users`);
  }

  @Post('users/:id')
  @OwnerOnly()
  async userUpdate(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Record<string, unknown>,
  ) {
    const dto = await this.userDto(body);
    await this.users.update(req.user, id, dto);
    if (id === req.user.id && dto.password) {
      // Password sendiri diganti → sesi admin panel ikut diperbarui lewat login ulang.
      setFlash(req, res, 'ok', 'Password diganti. Silakan login lagi.');
      return res.redirect(`${ADMIN_BASE}/login`);
    }
    setFlash(
      req,
      res,
      'ok',
      dto.password
        ? 'User disimpan. Password baru berlaku & semua sesi lama user ini dikeluarkan.'
        : 'User berhasil disimpan.',
    );
    return res.redirect(`${ADMIN_BASE}/users`);
  }

  @Post('users/:id/unlock')
  @OwnerOnly()
  async userUnlock(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
  ) {
    await this.users.unlock(req.user, id);
    setFlash(req, res, 'ok', 'Kunci login user dibuka.');
    return res.redirect(`${ADMIN_BASE}/users`);
  }

  // ───────────────────────── Jejak audit ─────────────────────────

  @Get('audit')
  async auditPage(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Query()
    q: { entity?: string; action?: string; user_id?: string; page?: string },
  ) {
    const page = Math.max(1, Number(q.page) || 1);
    const r = await this.auditLogs.list(
      req.user,
      q.entity || undefined,
      undefined,
      q.user_id || undefined,
      q.action || undefined,
      String(page),
    );
    const users = await this.prisma.user.findMany({
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    });
    return this.view.render(req, res, 'audit', 'audit', {
      title: 'Jejak Audit',
      q,
      users: users.map((u) => ({ ...u, selected: String(u.id) === q.user_id })),
      entities: [
        'transaction',
        'user',
        'product',
        'location',
        'partner',
        'vehicle',
        'packaging_unit',
        'min_level',
        'settings',
      ].map((e) => ({ value: e, selected: e === q.entity })),
      actions: Object.entries(ACTION_LABEL).map(([value, label]) => ({
        value,
        label,
        selected: value === q.action,
      })),
      rows: r.data.map((x) => ({
        id: Number(x.id),
        at: fmtDateTime(x.createdAt),
        user: x.user_name ?? '(sistem)',
        action: ACTION_LABEL[x.action] ?? x.action,
        entity: x.entity,
        entityId: x.entityId === null ? '' : Number(x.entityId),
        trxLink:
          x.entity === 'transaction' && x.entityId !== null
            ? `${ADMIN_BASE}/trx/${Number(x.entityId)}`
            : null,
        device: x.deviceId ?? '',
        ip: x.ipAddress ?? '',
        oldValues: x.oldValues ? JSON.stringify(x.oldValues, null, 2) : '',
        newValues: x.newValues ? JSON.stringify(x.newValues, null, 2) : '',
      })),
      prevUrl:
        page > 1 ? withQuery('/audit', { ...q }, { page: page - 1 }) : null,
      nextUrl: r.has_more
        ? withQuery('/audit', { ...q }, { page: page + 1 })
        : null,
    });
  }

  // ───────────────────────── Pengaturan ─────────────────────────

  @Get('settings')
  async settingsPage(@Req() req: AdminRequest, @Res() res: Response) {
    const s = await this.settings.all();
    const logo = s.company_logo_base64;
    return this.view.render(req, res, 'settings', 'settings', {
      title: 'Pengaturan',
      fields: SETTING_FIELDS.map((f) => ({
        ...f,
        type: f.type ?? 'text',
        value: s[f.name] ?? '',
      })),
      logo: logo
        ? logo.startsWith('data:')
          ? logo
          : `data:image/png;base64,${logo}`
        : null,
    });
  }

  @Post('settings')
  async settingsSave(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Body() body: Record<string, unknown>,
  ) {
    const values: Record<string, string> = {};
    for (const f of SETTING_FIELDS) {
      const v = str(body[f.name]).trim();
      if (f.required && !v)
        throw AppError.validation(`${f.label} wajib diisi.`);
      if (
        f.name !== 'company_name' &&
        !['company_address', 'company_phone'].includes(f.name)
      ) {
        if (!/^\d+([.,]\d+)?$/.test(v))
          throw AppError.validation(`${f.label} harus berupa angka.`);
        values[f.name] = v.replace(',', '.');
      } else {
        values[f.name] = v.slice(0, 255);
      }
    }
    await this.saveSettings(req.user, values);
    setFlash(req, res, 'ok', 'Pengaturan disimpan.');
    return res.redirect(`${ADMIN_BASE}/settings`);
  }

  @Post('settings/logo')
  @UseInterceptors(
    FileInterceptor('logo', {
      storage: memoryStorage(),
      limits: { fileSize: 300 * 1024 },
      fileFilter: (_req, file, cb) =>
        cb(null, /^image\/(png|jpeg)$/.test(file.mimetype)),
    }),
  )
  async logoSave(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Body('remove') remove?: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (remove === '1') {
      await this.saveSettings(req.user, { company_logo_base64: '' });
      setFlash(
        req,
        res,
        'ok',
        'Logo dihapus. Surat jalan memakai logo bawaan.',
      );
      return res.redirect(`${ADMIN_BASE}/settings`);
    }
    if (!file)
      throw AppError.validation(
        'Logo wajib berupa gambar PNG/JPG maksimal 300 KB.',
      );
    await this.saveSettings(req.user, {
      company_logo_base64: `data:${file.mimetype};base64,${file.buffer.toString('base64')}`,
    });
    setFlash(req, res, 'ok', 'Logo disimpan.');
    return res.redirect(`${ADMIN_BASE}/settings`);
  }

  /** Sama seperti PUT /settings: simpan + catat audit (nilai logo diringkas). */
  private async saveSettings(user: AuthUser, values: Record<string, string>) {
    const allowed = Object.keys(DEFAULT_SETTINGS);
    const clean = Object.fromEntries(
      Object.entries(values).filter(([k]) => allowed.includes(k)),
    );
    const short = (o: Record<string, string>) => ({
      ...o,
      company_logo_base64: o.company_logo_base64
        ? `(${Math.round(o.company_logo_base64.length / 1024)} KB)`
        : '',
    });
    const before = await this.settings.all();
    const after = await this.settings.update(clean);
    await this.audit.log({
      user,
      action: 'update',
      entity: 'settings',
      oldValues: short(before),
      newValues: short(after),
    });
  }
}
