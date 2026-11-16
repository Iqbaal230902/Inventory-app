import { Injectable, ValidationPipe } from '@nestjs/common';
import { Response } from 'express';
import { AppError } from '../common/app-error';
import { SettingsService } from '../settings/settings.service';
import { ADMIN_BASE, AdminRequest, takeFlash } from './admin-auth';
import { str } from './view-engine';

/**
 * Validasi body form dengan DTO yang sama seperti REST API. Pesan bawaan
 * class-validator (bahasa Inggris) diterjemahkan memakai label field form.
 */
function translate(label: string, constraints: Record<string, string>) {
  const [kind, msg] = Object.entries(constraints)[0] ?? ['', ''];
  // Pesan kustom berbahasa Indonesia dari DTO dipakai apa adanya.
  if (msg && !/\b(should|must|each value)\b/.test(msg)) return msg;
  switch (kind) {
    case 'isNotEmpty':
      return `${label} wajib diisi.`;
    case 'maxLength':
      return `${label} terlalu panjang.`;
    case 'minLength':
      return `${label} terlalu pendek.`;
    default:
      return `${label} tidak valid.`;
  }
}

export async function validated<T>(
  cls: new () => T,
  body: Record<string, unknown>,
  labels: Record<string, string> = {},
): Promise<T> {
  const pipe = new ValidationPipe({
    whitelist: true,
    transform: true,
    errorHttpStatusCode: 422,
    exceptionFactory: (errors) => {
      const e = errors[0];
      return AppError.validation(
        e
          ? translate(labels[e.property] ?? e.property, e.constraints ?? {})
          : 'Data tidak valid.',
      );
    },
  });
  return (await pipe.transform(body, { type: 'body', metatype: cls })) as T;
}

/** Checkbox HTML: ada (= "on") → true. */
export const bool = (v: unknown) => v === 'on' || v === '1' || v === 'true';
/** String kosong dari form → undefined. */
export const opt = (v: unknown) =>
  typeof v === 'string' && v.trim() !== '' ? v.trim() : undefined;
/** Nilai multi-checkbox → array angka. */
export const intList = (v: unknown): number[] =>
  (Array.isArray(v) ? v : v === undefined || v === '' ? [] : [v])
    .map(Number)
    .filter((n) => Number.isInteger(n) && n > 0);

/** "2026-11-16" (WIB) → Date awal hari; addDays=1 untuk batas akhir eksklusif. */
export function wibDay(v: string | undefined, addDays = 0): Date | undefined {
  if (!v || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return undefined;
  const d = new Date(`${v}T00:00:00+07:00`);
  if (Number.isNaN(d.getTime())) return undefined;
  return new Date(d.getTime() + addDays * 86400_000);
}

/** URL halaman yang sama dengan parameter query diganti. */
export function withQuery(
  path: string,
  q: Record<string, unknown>,
  patch: Record<string, unknown>,
) {
  const params = new URLSearchParams();
  for (const [k, v] of Object.entries({ ...q, ...patch })) {
    if (v !== undefined && v !== null && v !== '') params.set(k, str(v));
  }
  const s = params.toString();
  return `${ADMIN_BASE}${path}${s ? `?${s}` : ''}`;
}

@Injectable()
export class AdminView {
  constructor(private settings: SettingsService) {}

  /** Render halaman dengan layout + data bersama (user, menu aktif, pesan flash). */
  async render(
    req: AdminRequest,
    res: Response,
    view: string,
    nav: string,
    data: Record<string, unknown>,
  ) {
    const me = req.user;
    res.render(view, {
      ...data,
      base: ADMIN_BASE,
      me,
      isOwner: me?.role === 'owner',
      nav: { [nav]: true },
      flash: takeFlash(req, res),
      company: await this.settings.get('company_name'),
    });
  }
}
