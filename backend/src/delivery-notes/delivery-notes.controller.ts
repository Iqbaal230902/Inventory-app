import {
  Controller,
  Get,
  Header,
  Param,
  ParseIntPipe,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Response } from 'express';
import { existsSync, readFileSync } from 'fs';
import { join } from 'path';
import PDFDocument from 'pdfkit';
import * as QRCode from 'qrcode';
import { AppError } from '../common/app-error';
import {
  AuthUser,
  canAccessLocation,
  CurrentUser,
  Public,
} from '../common/auth-user';
import { tonId } from '../common/decimal';
import { zonedParts } from '../common/time';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import {
  TRX_INCLUDE,
  TrxWithRelations,
} from '../transactions/transaction.serializer';

/** Logo PT bawaan (backend/assets/logo.png) — dipakai bila logo belum diunggah di Profil Perusahaan. */
let defaultLogo: Buffer | null | undefined;
function defaultCompanyLogo(): Buffer | null {
  if (defaultLogo !== undefined) return defaultLogo;
  const candidates = [
    join(process.cwd(), 'assets', 'logo.png'),
    join(__dirname, '..', '..', 'assets', 'logo.png'), // src/delivery-notes (ts-jest)
    join(__dirname, '..', '..', '..', 'assets', 'logo.png'), // dist/src/delivery-notes
  ];
  const found = candidates.find((f) => existsSync(f));
  defaultLogo = found ? readFileSync(found) : null;
  return defaultLogo;
}

const esc = (s: string | number | null | undefined) =>
  String(s ?? '-').replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

export function formatPlate(p?: string | null) {
  if (!p) return '-';
  const m = p.match(/^([A-Z]{1,2})(\d{1,4})([A-Z]{0,3})$/);
  return m ? [m[1], m[2], m[3]].filter(Boolean).join(' ') : p;
}

function fmtDate(d: Date, tz: string) {
  const p = zonedParts(d, tz);
  const label =
    { 'Asia/Jakarta': 'WIB', 'Asia/Makassar': 'WITA', 'Asia/Jayapura': 'WIT' }[
      tz
    ] ?? '';
  return `${p.day}/${p.month}/${p.year} ${p.hour}:${p.minute} ${label}`.trim();
}

@Controller('delivery-notes')
export class DeliveryNotesController {
  constructor(
    private prisma: PrismaService,
    private settings: SettingsService,
    private config: ConfigService,
  ) {}

  @Get(':id/pdf')
  async pdf(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Res() res: Response,
  ) {
    const t = await this.prisma.transaction.findUnique({
      where: { id: BigInt(id) },
      include: TRX_INCLUDE,
    });
    if (!t || !canAccessLocation(user, t.locationId)) throw AppError.notFound();
    if (t.trxType !== 'OUT_SALE')
      throw AppError.validation(
        'Surat jalan hanya untuk transaksi barang keluar.',
      );
    const buf = await this.render(t);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${(t.docNo ?? 'SJ').replace(/\//g, '-')}.pdf"`,
    );
    res.end(buf);
  }

  /** Halaman publik ringkas untuk memverifikasi keaslian SJ dari QR code. */
  @Public()
  @Get('verify/:token')
  @Header('Content-Type', 'text/html; charset=utf-8')
  async verify(@Param('token') token: string) {
    const isUuid = /^[0-9a-f-]{36}$/i.test(token);
    const t = await this.prisma.transaction.findFirst({
      where: isUuid ? { clientUuid: token } : { verifyToken: token },
      include: TRX_INCLUDE,
    });
    const company = await this.settings.get('company_name');
    if (!t || t.trxType !== 'OUT_SALE') {
      return page(
        company,
        '<p class="bad">Surat jalan TIDAK DITEMUKAN. Dokumen ini kemungkinan tidak sah atau belum tersinkron.</p>',
      );
    }
    const item = t.items.find((i) => !i.supersededAt);
    const status =
      t.status === 'void'
        ? `<p class="bad">DIBATALKAN (VOID): ${esc(t.voidReason)}</p>`
        : '<p class="ok">✔ Surat jalan SAH dan tercatat di sistem.</p>';
    return page(
      company,
      `${status}<table>
      <tr><th>No. SJ</th><td>${esc(t.docNo)}${t.manualDocNo ? ` (manual: ${esc(t.manualDocNo)})` : ''}</td></tr>
      <tr><th>Tanggal</th><td>${esc(fmtDate(t.trxAt, t.location.timezone))}</td></tr>
      <tr><th>Asal</th><td>${esc(t.location.name)}</td></tr>
      <tr><th>Pelanggan</th><td>${esc(t.partnerName)}</td></tr>
      <tr><th>Produk</th><td>${esc(item?.product?.name)}</td></tr>
      <tr><th>Netto</th><td>${esc(tonId(t.netTon ?? item?.qtyTon ?? 0))} Ton</td></tr>
      <tr><th>No. Polisi</th><td>${esc(formatPlate(t.plateNumber))}</td></tr>
      <tr><th>Sopir</th><td>${esc(t.driverName)}</td></tr></table>`,
    );
  }

  private verifyUrl(t: TrxWithRelations) {
    const base = this.config.get<string>('PUBLIC_BASE_URL') ?? '';
    return `${base}/api/v1/delivery-notes/verify/${t.clientUuid}`;
  }

  async render(t: TrxWithRelations): Promise<Buffer> {
    const s = await this.settings.all();
    const qr = await QRCode.toBuffer(this.verifyUrl(t), {
      margin: 0,
      width: 160,
    });
    const doc = new PDFDocument({ size: 'A5', margin: 28 });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(c));
    const done = new Promise<Buffer>((r) =>
      doc.on('end', () => r(Buffer.concat(chunks))),
    );
    const W = doc.page.width - 56;

    // Kop: logo PT + nama PT di sampingnya
    let x = 28;
    const logos: Buffer[] = [];
    if (s.company_logo_base64) {
      logos.push(
        Buffer.from(
          s.company_logo_base64.replace(/^data:.*?;base64,/, ''),
          'base64',
        ),
      );
    }
    const fallback = defaultCompanyLogo();
    if (fallback) logos.push(fallback);
    for (const logo of logos) {
      try {
        doc.image(logo, 28, 26, { fit: [52, 52] });
        x = 88;
        break;
      } catch {
        /* logo tidak valid — coba logo bawaan */
      }
    }
    const contact = [s.company_address, s.company_phone]
      .filter(Boolean)
      .join(' · ');
    const textW = W - (x - 28) - 70;
    doc.font('Helvetica-Bold').fontSize(15);
    const nameH = doc.heightOfString(s.company_name, { width: textW });
    const blockH = nameH + (contact ? 12 : 0);
    const top = Math.max(26, 26 + (52 - blockH) / 2);
    doc.text(s.company_name, x, top, { width: textW });
    if (contact) {
      doc
        .font('Helvetica')
        .fontSize(8)
        .text(contact, x, doc.y + 2, { width: textW });
    }
    doc.image(qr, 28 + W - 60, 26, { width: 60 });
    doc
      .moveTo(28, 92)
      .lineTo(28 + W, 92)
      .stroke();

    doc
      .font('Helvetica-Bold')
      .fontSize(14)
      .text(t.printCount > 1 ? 'SURAT JALAN (COPY)' : 'SURAT JALAN', 28, 100, {
        width: W,
        align: 'center',
      });
    doc
      .font('Helvetica')
      .fontSize(9)
      .text(
        `No. ${t.docNo}${t.manualDocNo ? `  ·  Manual: ${t.manualDocNo}` : ''}`,
        { width: W, align: 'center' },
      );
    doc.moveDown(0.8);

    const rows: [string, string][] = [
      ['Tanggal', fmtDate(t.trxAt, t.location.timezone)],
      ['Dari', `${t.location.name}`],
      [
        'Kepada',
        [t.partnerName, t.partner?.address].filter(Boolean).join(' — '),
      ],
      ['No. Polisi', formatPlate(t.plateNumber)],
      ['Sopir', t.driverName ?? '-'],
    ];
    const labelW = 80;
    for (const [k, v] of rows) {
      const y = doc.y;
      doc.font('Helvetica').fontSize(9).text(k, 28, y, { width: labelW });
      doc.text(`: ${v}`, 28 + labelW, y, { width: W - labelW });
    }
    doc.moveDown(0.6);

    // Tabel barang
    const cols = [28, 210, 300, 28 + W];
    let y = doc.y;
    doc.rect(28, y, W, 18).fill('#eeeeee').fillColor('black');
    doc.font('Helvetica-Bold').fontSize(9);
    doc.text('Produk', cols[0] + 4, y + 5);
    doc.text('Kemasan', cols[1] + 4, y + 5);
    doc.text('Jumlah', cols[2] + 4, y + 5, {
      width: cols[3] - cols[2] - 8,
      align: 'right',
    });
    y += 18;
    doc.font('Helvetica');
    for (const i of t.items.filter((i) => !i.supersededAt)) {
      doc.text(i.product?.name ?? '-', cols[0] + 4, y + 5, {
        width: cols[1] - cols[0] - 8,
      });
      const pk = i.packagingUnit
        ? `${i.packagingUnit.name}${i.packageQty && !i.packagingUnit.isBulk ? ` × ${i.packageQty.toString()}` : ''}`
        : 'Curah';
      doc.text(pk, cols[1] + 4, y + 5, { width: cols[2] - cols[1] - 8 });
      doc.text(`${tonId(i.qtyTon)} Ton`, cols[2] + 4, y + 5, {
        width: cols[3] - cols[2] - 8,
        align: 'right',
      });
      y += 20;
      doc
        .moveTo(28, y)
        .lineTo(28 + W, y)
        .strokeColor('#cccccc')
        .stroke()
        .strokeColor('black');
    }
    doc.y = y + 8;
    if (t.grossTon && t.tareTon) {
      const yy = doc.y;
      doc
        .fontSize(9)
        .text(`Bruto: ${tonId(t.grossTon)} Ton`, 28, yy, { width: W / 3 });
      doc.text(`Tara: ${tonId(t.tareTon)} Ton`, 28 + W / 3, yy, {
        width: W / 3,
        align: 'center',
      });
      doc
        .font('Helvetica-Bold')
        .text(`Netto: ${tonId(t.netTon!)} Ton`, 28 + (2 * W) / 3, yy, {
          width: W / 3,
          align: 'right',
        });
      doc.font('Helvetica');
    }
    if (t.notes)
      doc
        .moveDown(0.5)
        .fontSize(8)
        .text(`Catatan: ${t.notes}`, 28, doc.y, { width: W });
    if (t.status === 'void')
      doc
        .moveDown(0.5)
        .font('Helvetica-Bold')
        .fillColor('red')
        .text('DIBATALKAN (VOID)', 28, doc.y, { width: W, align: 'center' })
        .fillColor('black')
        .font('Helvetica');

    // Tanda tangan
    const sy = Math.max(doc.y + 24, doc.page.height - 130);
    const cw = W / 3;
    ['Pengirim', 'Sopir', 'Penerima'].forEach((label, idx) => {
      doc
        .fontSize(9)
        .text(label, 28 + idx * cw, sy, { width: cw, align: 'center' });
      doc.text('(....................)', 28 + idx * cw, sy + 50, {
        width: cw,
        align: 'center',
      });
    });
    doc
      .fontSize(7)
      .fillColor('#666666')
      .text(
        `Dicetak ${fmtDate(new Date(), t.location.timezone)} · Oleh ${t.createdBy.name} · Scan QR untuk verifikasi keaslian`,
        28,
        doc.page.height - 40,
        { width: W, align: 'center' },
      );
    doc.end();
    return done;
  }
}

function page(company: string, body: string) {
  return `<!doctype html><html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Verifikasi Surat Jalan</title><style>
body{font-family:system-ui,sans-serif;max-width:480px;margin:24px auto;padding:0 16px;color:#222}
h1{font-size:18px}.ok{color:#1b7f3b;font-weight:600}.bad{color:#b3261e;font-weight:600}
table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:6px 4px;border-bottom:1px solid #eee;font-size:14px}th{width:35%;color:#555;font-weight:500}
</style></head><body><h1>${esc(company)}</h1><h2 style="font-size:15px">Verifikasi Surat Jalan</h2>${body}</body></html>`;
}
