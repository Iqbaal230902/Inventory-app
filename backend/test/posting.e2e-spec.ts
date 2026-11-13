/**
 * Uji posting stok (PRD 12 — strategi pengujian):
 * masuk, keluar, idempotensi, 10 request paralel, void, edit, sync offline,
 * presisi desimal, dan rekonsiliasi ledger vs saldo setelah setiap skenario.
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

describe('Posting stok (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let http: ReturnType<typeof request>;
  let ownerTok: string, adminTok: string, opTok: string, viewerTok: string;
  let loc: number,
    loc2: number,
    prodA: number,
    prodB: number,
    customer: number,
    karung: number;
  // Suffix unik per run: tes tidak perlu menghapus data sehingga aman diulang.
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
  const balance = async (productId: number, locationId = loc) =>
    (
      await prisma.stockBalance.findUnique({
        where: { locationId_productId: { locationId, productId } },
      })
    )?.qtyTon.toFixed(3) ?? '0.000';
  const reconcile = async () =>
    expect(await prisma.$queryRawUnsafe<any[]>(RECONCILE_SQL)).toEqual([]);
  const login = async (username: string, password: string) =>
    (
      await http
        .post('/api/v1/auth/login')
        .send({ username, password })
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
        data: { code: `A${run}`, name: 'Gudang Uji', type: 'gudang' },
      })
    ).id;
    loc2 = (
      await prisma.location.create({
        data: { code: `B${run}`, name: 'Gudang Lain', type: 'gudang' },
      })
    ).id;
    prodA = (
      await prisma.product.create({
        data: { code: `PA${run}`, name: 'Mesh 14/20', category: 'finished' },
      })
    ).id;
    prodB = (
      await prisma.product.create({
        data: { code: `PB${run}`, name: 'Mesh 20/40', category: 'finished' },
      })
    ).id;
    karung = (
      await prisma.packagingUnit.create({
        data: { name: 'Karung 50 kg', tonPerUnit: '0.050' },
      })
    ).id;
    customer = (
      await prisma.partner.create({
        data: { type: 'customer', name: 'PT Kaca' },
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
        username: uname('adm'),
        name: 'Admin',
        role: 'admin',
        passwordHash: hash,
        locations: { create: [{ locationId: loc }] },
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
    await prisma.user.create({
      data: {
        username: uname('vw'),
        name: 'Viewer',
        role: 'viewer',
        passwordHash: hash,
        locations: { create: [{ locationId: loc }] },
      },
    });
    ownerTok = await login(uname('own'), 'rahasia123');
    adminTok = await login(uname('adm'), 'rahasia123');
    opTok = await login(uname('opr'), 'rahasia123');
    viewerTok = await login(uname('vw'), 'rahasia123');
  });

  afterAll(async () => {
    await app?.close();
  });

  it('barang masuk menambah stok dan menghasilkan nomor BM', async () => {
    const res = await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(trx('IN_PRODUCTION', [{ product_id: prodA, qty_ton: '55.000' }]))
      .expect(201);
    expect(res.body.transaction.doc_no).toMatch(
      new RegExp(`^BM/A${run}/\\d{6}/0001$`),
    );
    expect(await balance(prodA)).toBe('55.000');
    await reconcile();
  });

  it('netto = bruto − tara dan harus sama dengan total produk', async () => {
    await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(
        trx('OUT_SALE', [{ product_id: prodA, qty_ton: '15.000' }], {
          partner_id: customer,
          gross_ton: '24.350',
          tare_ton: '8.450',
        }),
      )
      .expect(422);
    const ok = await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(
        trx('OUT_SALE', [{ product_id: prodA, qty_ton: '15,9' }], {
          partner_id: customer,
          gross_ton: '24,350',
          tare_ton: '8.450',
        }),
      )
      .expect(201);
    expect(ok.body.transaction.net_ton).toBe('15.900');
    expect(ok.body.transaction.doc_no).toMatch(`SJ/A${run}/`);
    expect(await balance(prodA)).toBe('39.100');
  });

  it('kiriman ulang dengan client_uuid sama tidak menggandakan stok', async () => {
    const body = trx('IN_SUPPLIER', [
      { product_id: prodB, package_qty: '300', packaging_unit_id: karung },
    ]);
    const a = await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(body)
      .expect(201);
    expect(a.body.transaction.items[0].qty_ton).toBe('15.000'); // 300 karung × 0,05
    const results = await Promise.all(
      [1, 2, 3].map(() =>
        http.post('/api/v1/transactions').set(auth(opTok)).send(body),
      ),
    );
    results.forEach((r) => expect(r.body.status).toBe('duplicate'));
    expect(await balance(prodB)).toBe('15.000');
    await reconcile();
  });

  it('10 request keluar paralel pada produk sama tidak membuat stok negatif', async () => {
    // Stok A = 39,100 → 10 × 5 ton: hanya 7 yang boleh berhasil
    const reqs = Array.from({ length: 10 }, () =>
      http
        .post('/api/v1/transactions')
        .set(auth(opTok))
        .send(
          trx('OUT_SALE', [{ product_id: prodA, qty_ton: '5.000' }], {
            partner_id: customer,
          }),
        ),
    );
    const res = await Promise.all(reqs);
    const ok = res.filter((r) => r.status === 201).length;
    const rejected = res.filter(
      (r) => r.body?.error?.code === 'INSUFFICIENT_STOCK',
    ).length;
    expect(ok).toBe(7);
    expect(rejected).toBe(3);
    expect(await balance(prodA)).toBe('4.100');
    // Nomor SJ unik & berurutan
    const docs = res
      .filter((r) => r.status === 201)
      .map((r) => r.body.transaction.doc_no);
    expect(new Set(docs).size).toBe(7);
    await reconcile();
  });

  it('operator tidak boleh di lokasi lain, viewer tidak boleh input', async () => {
    await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(
        trx('IN_PRODUCTION', [{ product_id: prodA, qty_ton: '1' }], {
          location_id: loc2,
        }),
      )
      .expect(403);
    await http
      .post('/api/v1/transactions')
      .set(auth(viewerTok))
      .send(trx('IN_PRODUCTION', [{ product_id: prodA, qty_ton: '1' }]))
      .expect(403);
  });

  it('tonase di atas batas wajar butuh konfirmasi', async () => {
    const r = await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(trx('IN_PRODUCTION', [{ product_id: prodA, qty_ton: '159' }]))
      .expect(422);
    expect(r.body.error.code).toBe('NEEDS_CONFIRMATION');
  });

  it('void: admin hanya mengajukan, owner membuat mutasi pembalik', async () => {
    const created = await http
      .post('/api/v1/transactions')
      .set(auth(adminTok))
      .send(trx('IN_PRODUCTION', [{ product_id: prodA, qty_ton: '10.000' }]))
      .expect(201);
    const id = created.body.transaction.id;
    expect(await balance(prodA)).toBe('14.100');

    const req = await http
      .post(`/api/v1/transactions/${id}/void`)
      .set(auth(adminTok))
      .send({ reason: 'salah input' })
      .expect(200);
    expect(req.body.requested).toBe(true);
    expect(await balance(prodA)).toBe('14.100');

    await http
      .post(`/api/v1/transactions/${id}/void`)
      .set(auth(opTok))
      .send({ reason: 'x' })
      .expect(403);
    const v = await http
      .post(`/api/v1/transactions/${id}/void`)
      .set(auth(ownerTok))
      .send({ reason: 'salah input' })
      .expect(200);
    expect(v.body.transaction.status).toBe('void');
    expect(v.body.transaction.void_transaction.doc_no).toMatch(/^VD\//);
    expect(await balance(prodA)).toBe('4.100');
    await http
      .post(`/api/v1/transactions/${id}/void`)
      .set(auth(ownerTok))
      .send({ reason: 'lagi' })
      .expect(422);
    // Hapus permanen ditolak oleh trigger database
    await expect(
      prisma.$executeRawUnsafe(`DELETE FROM transactions WHERE id = ${id}`),
    ).rejects.toThrow();
    await expect(
      prisma.$executeRawUnsafe(`UPDATE stock_ledger SET qty_change_ton = 0`),
    ).rejects.toThrow();
    await reconcile();
  });

  it('edit transaksi membalik ledger lama dan menulis ledger baru', async () => {
    const created = await http
      .post('/api/v1/transactions')
      .set(auth(opTok))
      .send(trx('IN_PRODUCTION', [{ product_id: prodB, qty_ton: '10.000' }]))
      .expect(201);
    const id = created.body.transaction.id;
    expect(await balance(prodB)).toBe('25.000');
    await http
      .patch(`/api/v1/transactions/${id}`)
      .set(auth(opTok))
      .send({ edit_reason: 'x' })
      .expect(403);
    const e = await http
      .patch(`/api/v1/transactions/${id}`)
      .set(auth(adminTok))
      .send({
        edit_reason: 'salah ketik',
        items: [{ product_id: prodB, qty_ton: '12.500' }],
      })
      .expect(200);
    expect(e.body.items).toHaveLength(1);
    expect(e.body.total_ton).toBe('12.500');
    expect(await balance(prodB)).toBe('27.500');
    const detail = await http
      .get(`/api/v1/transactions/${id}`)
      .set(auth(adminTok))
      .expect(200);
    expect(detail.body.history.map((h: any) => h.action)).toEqual([
      'create',
      'update',
    ]);
    await reconcile();
  });

  it('transaksi lama terkunci (H+1) → LOCKED', async () => {
    const old = new Date(Date.now() - 3 * 86400_000).toISOString();
    const created = await http
      .post('/api/v1/transactions')
      .set(auth(adminTok))
      .send(
        trx('IN_PRODUCTION', [{ product_id: prodB, qty_ton: '1.000' }], {
          trx_at: old,
        }),
      )
      .expect(201);
    const r = await http
      .patch(`/api/v1/transactions/${created.body.transaction.id}`)
      .set(auth(adminTok))
      .send({ edit_reason: 'x', notes: 'baru' })
      .expect(409);
    expect(r.body.error.code).toBe('LOCKED');
  });

  it('sync push: stok kurang → diterima sebagai pending_approval, duplikat aman, data rusak ditolak', async () => {
    const short = trx('OUT_SALE', [{ product_id: prodA, qty_ton: '6.000' }], {
      partner_name: 'Pembeli Tunai',
    });
    const good = trx('OUT_SALE', [{ product_id: prodB, qty_ton: '2.500' }], {
      partner_id: customer,
    });
    const bad = {
      ...trx('OUT_SALE', [{ product_id: prodB, qty_ton: 'abc' }]),
      partner_id: customer,
    };
    const r = await http
      .post('/api/v1/sync/push')
      .set(auth(opTok))
      .send({ transactions: [short, good, bad] })
      .expect(200);
    const byUuid = Object.fromEntries(
      r.body.results.map((x: any) => [x.client_uuid, x]),
    );
    expect(byUuid[short.client_uuid].status).toBe('ok');
    expect(byUuid[short.client_uuid].transaction.status).toBe(
      'pending_approval',
    );
    expect(byUuid[good.client_uuid].status).toBe('ok');
    expect(byUuid[bad.client_uuid].status).toBe('rejected');
    expect(await balance(prodA)).toBe('-1.900');

    const again = await http
      .post('/api/v1/sync/push')
      .set(auth(opTok))
      .send({ transactions: [short, good] })
      .expect(200);
    again.body.results.forEach((x: any) => expect(x.status).toBe('duplicate'));
    expect(await balance(prodB)).toBe('26.000');

    const dash = await http
      .get('/api/v1/dashboard')
      .set(auth(adminTok))
      .expect(200);
    expect(dash.body.pending_approval_count).toBe(1);
    const id = byUuid[short.client_uuid].transaction.id;
    const ap = await http
      .post(`/api/v1/transactions/${id}/approve`)
      .set(auth(adminTok))
      .send({ note: 'cek fisik ok' })
      .expect(200);
    expect(ap.body.status).toBe('posted');
    await reconcile();
  });

  it('pull mengembalikan master data & saldo resmi', async () => {
    const r = await http.get('/api/v1/sync/pull').set(auth(opTok)).expect(200);
    expect(r.body.products.length).toBeGreaterThanOrEqual(2);
    expect(r.body.locations.map((l: any) => l.id)).toEqual([loc]);
    expect(
      r.body.balances.find((b: any) => b.product_id === prodB).qty_ton,
    ).toBe('26.000');
    const delta = await http
      .get(`/api/v1/sync/pull?since=${encodeURIComponent(r.body.server_time)}`)
      .set(auth(opTok))
      .expect(200);
    expect(delta.body.full).toBe(false);
    // Delta inklusif (>=) dengan presisi detik: hanya data yang berubah sejak detik `since`.
    const sinceSec = Math.floor(Date.parse(r.body.server_time) / 1000) * 1000;
    delta.body.products.forEach((p: any) =>
      expect(
        Date.parse(p.updated_at ?? r.body.server_time),
      ).toBeGreaterThanOrEqual(sinceSec),
    );
    expect(delta.body.products.length).toBeLessThanOrEqual(
      r.body.products.length,
    );
  });

  it('presisi: 200 transaksi acak 3 desimal identik dengan saldo', async () => {
    let expected = 0n; // dalam gram (milli-ton) agar eksak
    const start = BigInt(Math.round(Number(await balance(prodB)) * 1000));
    for (let batch = 0; batch < 4; batch++) {
      const txs = Array.from({ length: 50 }, () => {
        const grams = BigInt(Math.floor(Math.random() * 30000) + 1);
        expected += grams;
        const s = `${grams / 1000n}.${String(grams % 1000n).padStart(3, '0')}`;
        return trx('IN_PRODUCTION', [{ product_id: prodB, qty_ton: s }]);
      });
      const r = await http
        .post('/api/v1/sync/push')
        .set(auth(opTok))
        .send({ transactions: txs })
        .expect(200);
      r.body.results.forEach((x: any) => expect(x.status).toBe('ok'));
    }
    const total = start + expected;
    expect(await balance(prodB)).toBe(
      `${total / 1000n}.${String(total % 1000n).padStart(3, '0')}`,
    );
    await reconcile();
  });

  it('user nonaktif langsung ditolak 401', async () => {
    const opr = await prisma.user.findUniqueOrThrow({
      where: { username: uname('opr') },
    });
    await http
      .put(`/api/v1/users/${opr.id}`)
      .set(auth(ownerTok))
      .send({
        name: 'Operator',
        username: uname('opr'),
        role: 'operator',
        location_ids: [loc],
        is_active: false,
      })
      .expect(200);
    const r = await http.get('/api/v1/dashboard').set(auth(opTok)).expect(401);
    expect(r.body.error.code).toBe('USER_INACTIVE');
  });

  it('login gagal 5× mengunci akun', async () => {
    for (let i = 0; i < 5; i++) {
      await http
        .post('/api/v1/auth/login')
        .send({ username: uname('vw'), password: 'salah' })
        .expect(401);
    }
    const r = await http
      .post('/api/v1/auth/login')
      .send({ username: uname('vw'), password: 'rahasia123' })
      .expect(429);
    expect(r.body.error.code).toBe('ACCOUNT_LOCKED');
  });

  it('surat jalan PDF dan halaman verifikasi QR', async () => {
    const list = await http
      .get(`/api/v1/transactions?type=OUT_SALE&location_id=${loc}`)
      .set(auth(adminTok))
      .expect(200);
    const t = list.body.data[0];
    const pdf = await http
      .get(`/api/v1/delivery-notes/${t.id}/pdf`)
      .set(auth(adminTok))
      .expect(200);
    expect(pdf.headers['content-type']).toContain('application/pdf');
    const v = await http
      .get(`/api/v1/delivery-notes/verify/${t.client_uuid}`)
      .expect(200);
    expect(v.text).toContain('SAH');
    const p1 = await http
      .post(`/api/v1/transactions/${t.id}/print`)
      .set(auth(adminTok))
      .send({ channel: 'pdf' })
      .expect(200);
    const p2 = await http
      .post(`/api/v1/transactions/${t.id}/print`)
      .set(auth(adminTok))
      .send({ channel: 'pdf' })
      .expect(200);
    expect([p1.body.is_copy, p2.body.is_copy]).toEqual([false, true]);
  });
});
