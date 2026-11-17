/**
 * Bahan baku mentah per rit (IN_RAW): dihitung per truk tanpa tonase, aturan satuan,
 * penyesuaian, void, ringkasan dashboard (hari ini & bulan ini), rekonsiliasi ledger.
 */
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { setupApp } from '../src/setup-app';
import { RECONCILE_SQL } from '../scripts/reconcile';

jest.setTimeout(120_000);

describe('Bahan baku mentah per rit (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let http: ReturnType<typeof request>;
  let ownerTok: string, opTok: string;
  let loc: number, raw: number, mesh: number;
  const run = Math.random().toString(36).slice(2, 8).toUpperCase();
  const uname = (u: string) => `${u}_${run}`.toLowerCase();
  const now = () => new Date().toISOString();
  const auth = (t: string) => ({ Authorization: `Bearer ${t}` });
  const trx = (type: string, items: object[], extra: object = {}) => ({
    client_uuid: randomUUID(),
    trx_type: type,
    location_id: loc,
    trx_at: now(),
    client_created_at: now(),
    items,
    ...extra,
  });
  const post = (tok: string, body: object) =>
    http.post('/api/v1/transactions').set(auth(tok)).send(body);
  const balance = async (productId: number) =>
    (
      await prisma.stockBalance.findUnique({
        where: { locationId_productId: { locationId: loc, productId } },
      })
    )?.qtyTon.toFixed(3) ?? '0.000';
  const reconcile = async () =>
    expect(await prisma.$queryRawUnsafe<any[]>(RECONCILE_SQL)).toEqual([]);
  const login = async (username: string) =>
    (
      await http
        .post('/api/v1/auth/login')
        .send({ username, password: 'rahasia123' })
        .expect(200)
    ).body.access_token as string;

  beforeAll(async () => {
    const mod = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = setupApp(mod.createNestApplication());
    await app.init();
    prisma = app.get(PrismaService);
    http = request(app.getHttpServer());

    loc = (
      await prisma.location.create({
        data: { code: `R${run}`, name: 'Gudang Bahan', type: 'gudang' },
      })
    ).id;
    raw = (
      await prisma.product.create({
        data: {
          code: `RW${run}`,
          name: 'Bahan Baku Mentah',
          category: 'raw',
          unit: 'rit',
        },
      })
    ).id;
    mesh = (
      await prisma.product.create({
        data: { code: `RM${run}`, name: 'Mesh 8/14', category: 'finished' },
      })
    ).id;
    const hash = await bcrypt.hash('rahasia123', 4);
    await prisma.user.create({
      data: {
        username: uname('own'),
        name: 'Owner',
        role: 'owner',
        passwordHash: hash,
      },
    });
    await prisma.user.create({
      data: {
        username: uname('opr'),
        name: 'Operator',
        role: 'operator',
        passwordHash: hash,
        locations: { create: [{ locationId: loc }] },
      },
    });
    ownerTok = await login(uname('own'));
    opTok = await login(uname('opr'));
  });

  afterAll(() => app.close());

  it('operator mencatat bahan baku masuk per truk (rit), tanpa tonase', async () => {
    const r = await post(
      opTok,
      trx('IN_RAW', [{ product_id: raw, qty_ton: '3' }], {
        plate_number: 'bg 9001 ab',
        driver_name: 'Pak Udin',
      }),
    ).expect(201);
    const t = r.body.transaction;
    expect(t.doc_no).toMatch(`BB/R${run}/`);
    expect(t.total_rit).toBe('3');
    expect(t.total_ton).toBe('0.000');
    expect(t.items[0].unit).toBe('rit');
    expect(t.plate_number).toBe('BG9001AB');
    expect(await balance(raw)).toBe('3.000');

    await post(
      opTok,
      trx('IN_RAW', [{ product_id: raw, qty_ton: '2' }]),
    ).expect(201);
    expect(await balance(raw)).toBe('5.000');
    await reconcile();
  });

  it('menolak input yang tidak sesuai aturan satuan rit', async () => {
    const cases: [object, RegExp][] = [
      [trx('IN_RAW', [{ product_id: raw, qty_ton: '1.5' }]), /bilangan bulat/],
      [
        trx('IN_RAW', [{ product_id: mesh, qty_ton: '10' }]),
        /bukan bahan baku mentah/,
      ],
      [
        trx('IN_SUPPLIER', [{ product_id: raw, qty_ton: '10' }]),
        /Bahan Baku Masuk/,
      ],
      [
        trx('IN_RAW', [{ product_id: raw, qty_ton: '1' }], {
          gross_ton: '20',
          tare_ton: '8',
        }),
        /tanpa bruto\/tara/,
      ],
    ];
    for (const [body, msg] of cases) {
      const r = await post(opTok, body).expect(422);
      expect(r.body.error.message).toMatch(msg);
    }
    expect(await balance(raw)).toBe('5.000');
  });

  it('penyesuaian rit memakai satuan rit di pesan stok kurang', async () => {
    await post(
      ownerTok,
      trx('ADJUSTMENT', [{ product_id: raw, qty_ton: '1', direction: 'out' }], {
        notes: 'Koreksi hitung truk',
      }),
    ).expect(201);
    expect(await balance(raw)).toBe('4.000');
    const r = await post(
      ownerTok,
      trx('ADJUSTMENT', [{ product_id: raw, qty_ton: '9', direction: 'out' }], {
        notes: 'Koreksi',
      }),
    ).expect(422);
    expect(r.body.error.code).toBe('INSUFFICIENT_STOCK');
    expect(r.body.error.message).toMatch(/hanya 4 Rit \(diminta 9 Rit\)/);
    await reconcile();
  });

  it('dashboard: stok & jumlah truk (rit), total ton hanya pasir mesh', async () => {
    await post(
      opTok,
      trx('IN_SUPPLIER', [{ product_id: mesh, qty_ton: '10.500' }]),
    ).expect(201);
    const d = (
      await http
        .get(`/api/v1/dashboard?location_id=${loc}`)
        .set(auth(ownerTok))
        .expect(200)
    ).body;
    expect(d.total_ton).toBe(
      d.products
        .filter((p: any) => p.unit === 'ton')
        .reduce((s: number, p: any) => s + Number(p.qty_ton), 0)
        .toFixed(3),
    );
    const rawRow = d.products.find((p: any) => p.product_id === raw);
    expect(rawRow.unit).toBe('rit');
    expect(rawRow.qty_ton).toBe('4.000');
    expect(d.raw.qty_rit).toBe('4');
    expect(d.raw.today_in_rit).toBe('5'); // 3 + 2 truk; penyesuaian tidak dihitung
    expect(d.raw.month_in_rit).toBe('5');
    expect(d.raw).not.toHaveProperty('est_ton');
    expect(d.today.in_ton).toBe('10.500'); // rit tidak ikut tonase harian
  });

  it('void bahan baku masuk mengembalikan stok rit', async () => {
    const r = await post(
      opTok,
      trx('IN_RAW', [{ product_id: raw, qty_ton: '1' }]),
    ).expect(201);
    expect(await balance(raw)).toBe('5.000');
    await http
      .post(`/api/v1/transactions/${r.body.transaction.id}/void`)
      .set(auth(ownerTok))
      .send({ reason: 'Salah input' })
      .expect(200);
    expect(await balance(raw)).toBe('4.000');
    await reconcile();
  });

  it('sync pull menyertakan satuan produk', async () => {
    const r = await http.get('/api/v1/sync/pull').set(auth(opTok)).expect(200);
    expect(r.body.products.find((p: any) => p.id === raw).unit).toBe('rit');
    expect(r.body).not.toHaveProperty('truck_types');
  });
});
