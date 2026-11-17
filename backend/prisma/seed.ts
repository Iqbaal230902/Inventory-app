/**
 * Seed data awal. Jalankan: npm run seed            (master data + user)
 *                           npm run seed -- --demo  (+ saldo awal demo via ledger)
 */
import { NestFactory } from '@nestjs/core';
import * as bcrypt from 'bcryptjs';
import { randomUUID } from 'crypto';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { PostingService } from '../src/transactions/posting.service';

async function main() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });
  const prisma = app.get(PrismaService);

  // Saat ini hanya 1 gudang. Gudang baru ditambah Owner lewat
  // Lainnya → Master Data → Gudang / Lokasi.
  const locs = [{ code: 'GDA', name: 'Gudang A', type: 'gudang' as const }];
  for (const l of locs) {
    await prisma.location.upsert({
      where: { code: l.code },
      update: {},
      create: l,
    });
  }
  const gda = await prisma.location.findUniqueOrThrow({
    where: { code: 'GDA' },
  });

  // 4 jenis pasir silika yang dijual.
  const products = [
    {
      code: 'M0408',
      name: 'Mesh 4/8',
      meshSize: '4/8',
      category: 'finished' as const,
      sortOrder: 1,
    },
    {
      code: 'M0814',
      name: 'Mesh 8/14',
      meshSize: '8/14',
      category: 'finished' as const,
      sortOrder: 2,
    },
    {
      code: 'M1420',
      name: 'Mesh 14/20',
      meshSize: '14/20',
      category: 'finished' as const,
      sortOrder: 3,
    },
    {
      code: 'M2040',
      name: 'Mesh 20/40',
      meshSize: '20/40',
      category: 'finished' as const,
      sortOrder: 4,
    },
  ];
  for (const p of products) {
    await prisma.product.upsert({
      where: { code: p.code },
      update: {},
      create: p,
    });
  }

  if ((await prisma.packagingUnit.count()) === 0) {
    await prisma.packagingUnit.createMany({
      data: [
        { name: 'Curah', tonPerUnit: '1.000', isBulk: true },
        { name: 'Jumbo Bag 1 Ton', tonPerUnit: '1.000' },
        { name: 'Karung 50 kg', tonPerUnit: '0.050' },
      ],
    });
  }

  const users = [
    {
      username: 'owner',
      name: 'Pemilik',
      role: 'owner' as const,
      pw: 'owner12345',
      locs: [],
    },
    {
      username: 'admin',
      name: 'Kepala Gudang',
      role: 'admin' as const,
      pw: 'admin12345',
      locs: [gda.id],
    },
    {
      username: 'operator',
      name: 'Operator Timbangan',
      role: 'operator' as const,
      pw: 'operator123',
      locs: [gda.id],
    },
    {
      username: 'viewer',
      name: 'Akuntan',
      role: 'viewer' as const,
      pw: 'viewer12345',
      locs: [gda.id],
    },
  ];
  for (const u of users) {
    const exists = await prisma.user.findUnique({
      where: { username: u.username },
    });
    if (exists) continue;
    await prisma.user.create({
      data: {
        username: u.username,
        name: u.name,
        role: u.role,
        passwordHash: await bcrypt.hash(u.pw, 10),
        locations: { create: u.locs.map((locationId) => ({ locationId })) },
      },
    });
  }

  if ((await prisma.partner.count()) === 0) {
    await prisma.partner.createMany({
      data: [
        {
          type: 'customer',
          name: 'PT Kaca Nusantara',
          phone: '0711-555-010',
          address: 'Palembang',
        },
        {
          type: 'customer',
          name: 'CV Beton Jaya',
          phone: '0812-0000-1111',
          address: 'Prabumulih',
        },
        {
          type: 'supplier',
          name: 'Tambang Rakyat Sumber Makmur',
          address: 'Muara Enim',
        },
      ],
    });
  }
  await prisma.vehicle.upsert({
    where: { plateNumber: 'BG1234XY' },
    update: {},
    create: {
      plateNumber: 'BG1234XY',
      defaultDriver: 'Pak Darto',
      standardTareTon: '8.450',
    },
  });

  const m1420 = await prisma.product.findUniqueOrThrow({
    where: { code: 'M1420' },
  });
  await prisma.stockMinLevel.upsert({
    where: {
      locationId_productId: { locationId: gda.id, productId: m1420.id },
    },
    update: {},
    create: { locationId: gda.id, productId: m1420.id, minTon: '50.000' },
  });

  if (
    process.argv.includes('--demo') &&
    (await prisma.transaction.count()) === 0
  ) {
    const posting = app.get(PostingService);
    const owner = await prisma.user.findUniqueOrThrow({
      where: { username: 'owner' },
    });
    // Saldo awal hanya untuk pasir mesh (ton); bahan baku mentah (rit) mulai dari 0.
    const all = await prisma.product.findMany({
      where: { isActive: true, unit: 'ton' },
    });
    const opening: Record<string, string> = {
      M0408: '85.500',
      M0814: '140.250',
      M1420: '55.000',
      M2040: '98.750',
    };
    const now = new Date().toISOString();
    await posting.create(
      {
        id: owner.id,
        name: owner.name,
        username: owner.username,
        role: 'owner',
        locationIds: null,
      },
      {
        client_uuid: randomUUID(),
        trx_type: 'ADJUSTMENT',
        location_id: gda.id,
        trx_at: now,
        client_created_at: now,
        notes: 'Saldo awal (hasil opname fisik sebelum go-live)',
        items: all.map((p) => ({
          product_id: p.id,
          qty_ton: opening[p.code] ?? '0.001',
          direction: 'in' as const,
        })),
      },
    );
    console.log('Saldo awal demo diposting ke Gudang A.');
  }

  console.log(
    'Seed selesai. Login: owner/owner12345, admin/admin12345, operator/operator123, viewer/viewer12345',
  );
  await app.close();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
