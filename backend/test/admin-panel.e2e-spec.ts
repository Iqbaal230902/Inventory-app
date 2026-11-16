/**
 * Admin panel (/admin-panel, Handlebars): login cookie, RBAC, anti-CSRF origin,
 * alur void (Admin ajukan → Owner VOID) lewat form, ekspor CSV, dan sesi batal
 * setelah password diganti.
 */
import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { RECONCILE_SQL } from '../scripts/reconcile';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { setupApp } from '../src/setup-app';

jest.setTimeout(120_000);

describe('Admin panel (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let http: ReturnType<typeof request>;
  let loc: number, prod: number;
  const run = Math.random().toString(36).slice(2, 8).toUpperCase();
  const uname = (u: string) => `ap_${u}_${run}`.toLowerCase();
  const PW = 'rahasia123';

  /** Login form → cookie sesi admin (atau null bila ditolak). */
  const panelLogin = async (username: string, password = PW) => {
    const res = await http
      .post('/admin-panel/login')
      .type('form')
      .send({ username, password, next: '/admin-panel' })
      .expect(302);
    const cookies = ([] as string[]).concat(res.headers['set-cookie'] ?? []);
    const c = cookies.find((x) => x.startsWith('bam_admin='));
    return c ? c.split(';')[0] : null;
  };
  /** Pesan flash dari halaman tujuan redirect. */
  const flashOf = (res: request.Response) => {
    const cookies = ([] as string[]).concat(res.headers['set-cookie'] ?? []);
    const c = cookies.find((x) => x.startsWith('bam_flash='));
    if (!c) return null;
    return JSON.parse(decodeURIComponent(c.split(';')[0].slice(10))) as {
      type: string;
      message: string;
    };
  };

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
        data: { code: `P${run}`, name: 'Gudang Panel', type: 'gudang' },
      })
    ).id;
    prod = (
      await prisma.product.create({
        data: {
          code: `AP${run}`,
          name: 'Mesh Uji Panel',
          category: 'finished',
        },
      })
    ).id;
    const hash = await bcrypt.hash(PW, 4);
    for (const role of ['owner', 'admin', 'viewer'] as const) {
      await prisma.user.create({
        data: {
          name: `Panel ${role}`,
          username: uname(role),
          role,
          passwordHash: hash,
          locations:
            role === 'owner' ? undefined : { create: [{ locationId: loc }] },
        },
      });
    }
  });

  afterAll(async () => {
    await app.close();
  });

  it('tanpa login diarahkan ke halaman login; API tetap di /api/v1', async () => {
    const res = await http.get('/admin-panel/trx').expect(302);
    expect(res.headers.location).toBe(
      '/admin-panel/login?next=%2Fadmin-panel%2Ftrx',
    );
    await http.get('/admin-panel/login').expect(200).expect(/Masuk/);
    await http.post('/api/v1/auth/login').send({}).expect(422);
  });

  it('viewer & password salah ditolak; owner berhasil', async () => {
    expect(await panelLogin(uname('viewer'))).toBeNull();
    expect(await panelLogin(uname('owner'), 'salah-password')).toBeNull();
    const c = await panelLogin(uname('owner'));
    expect(c).toBeTruthy();
    for (const p of [
      '',
      '/trx',
      '/reports',
      '/master/partners',
      '/master/locations',
      '/min-levels',
      '/users',
      '/audit',
      '/settings',
    ]) {
      await http.get(`/admin-panel${p}`).set('Cookie', c!).expect(200);
    }
  });

  it('admin tidak bisa membuka halaman khusus Owner', async () => {
    const c = (await panelLogin(uname('admin')))!;
    await http.get('/admin-panel/users').set('Cookie', c).expect(403);
    await http
      .get('/admin-panel/master/locations')
      .set('Cookie', c)
      .expect(403);
    await http.get('/admin-panel/master/partners').set('Cookie', c).expect(200);
  });

  it('POST dari origin lain ditolak (anti-CSRF)', async () => {
    const c = (await panelLogin(uname('owner')))!;
    const name = `Evil ${run}`;
    const res = await http
      .post('/admin-panel/master/partners')
      .set('Cookie', c)
      .set('Origin', 'https://evil.example')
      .type('form')
      .send({ name, type: 'customer', is_active: 'on' })
      .expect(302);
    expect(flashOf(res)?.type).toBe('error');
    expect(await prisma.partner.count({ where: { name } })).toBe(0);
  });

  it('admin mengajukan void, owner mem-VOID lewat form; stok & ledger konsisten', async () => {
    const owner = await prisma.user.findUniqueOrThrow({
      where: { username: uname('owner') },
    });
    const tok = (
      await http
        .post('/api/v1/auth/login')
        .send({ username: uname('owner'), password: PW })
        .expect(200)
    ).body.access_token as string;
    const created = await http
      .post('/api/v1/transactions')
      .set('Authorization', `Bearer ${tok}`)
      .send({
        client_uuid: randomUUID(),
        trx_type: 'IN_SUPPLIER',
        location_id: loc,
        partner_name: 'Supplier Panel',
        trx_at: new Date().toISOString(),
        client_created_at: new Date().toISOString(),
        items: [{ product_id: prod, qty_ton: '12.345' }],
      })
      .expect(201);
    const id = created.body.transaction.id as number;
    expect(owner.id).toBeGreaterThan(0);

    const adminC = (await panelLogin(uname('admin')))!;
    const empty = await http
      .post(`/admin-panel/trx/${id}/void`)
      .set('Cookie', adminC)
      .type('form')
      .send({ reason: '' })
      .expect(302);
    expect(flashOf(empty)?.message).toBe('Alasan void wajib diisi.');

    const req1 = await http
      .post(`/admin-panel/trx/${id}/void`)
      .set('Cookie', adminC)
      .type('form')
      .send({ reason: 'Salah input' })
      .expect(302);
    expect(flashOf(req1)?.message).toMatch(/Pengajuan void/);
    let t = await prisma.transaction.findUniqueOrThrow({
      where: { id: BigInt(id) },
    });
    expect(t.status).toBe('posted');
    expect(t.voidRequestedAt).not.toBeNull();

    const ownerC = (await panelLogin(uname('owner')))!;
    await http
      .get(`/admin-panel/trx/${id}`)
      .set('Cookie', ownerC)
      .expect(200)
      .expect(/Batalkan \(VOID\)/);
    await http
      .post(`/admin-panel/trx/${id}/void`)
      .set('Cookie', ownerC)
      .type('form')
      .send({ reason: 'Disetujui Owner' })
      .expect(302);
    t = await prisma.transaction.findUniqueOrThrow({
      where: { id: BigInt(id) },
    });
    expect(t.status).toBe('void');
    const bal = await prisma.stockBalance.findUnique({
      where: { locationId_productId: { locationId: loc, productId: prod } },
    });
    expect(bal?.qtyTon.toFixed(3)).toBe('0.000');
    expect(await prisma.$queryRawUnsafe<any[]>(RECONCILE_SQL)).toEqual([]);

    const csv = await http
      .get(`/admin-panel/reports/transactions.csv?location_id=${loc}`)
      .set('Cookie', ownerC)
      .expect(200)
      .expect('Content-Type', /text\/csv/);
    expect(csv.text).toContain('Supplier Panel');
    expect(csv.text).toContain('12,345');
  });

  it('sesi admin panel batal setelah password diganti', async () => {
    const c = (await panelLogin(uname('admin')))!;
    await http.get('/admin-panel').set('Cookie', c).expect(200);
    await prisma.user.update({
      where: { username: uname('admin') },
      data: { passwordHash: await bcrypt.hash('passwordBaru1', 4) },
    });
    await http.get('/admin-panel').set('Cookie', c).expect(302);
  });
});
