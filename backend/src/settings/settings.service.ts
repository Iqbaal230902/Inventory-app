import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export const DEFAULT_SETTINGS: Record<string, string> = {
  company_name: 'CV Pasir Silika',
  company_address: '',
  company_phone: '',
  company_logo_base64: '',
  shrink_tolerance_pct: '2',
  production_loss_threshold_pct: '5',
  max_net_ton_per_trx: '60',
  lock_after_days: '1',
  duplicate_plate_window_min: '15',
};

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async all(): Promise<Record<string, string>> {
    const rows = await this.prisma.appSetting.findMany();
    const out = { ...DEFAULT_SETTINGS };
    for (const r of rows) out[r.key] = r.value ?? '';
    return out;
  }

  async get(key: string): Promise<string> {
    const row = await this.prisma.appSetting.findUnique({ where: { key } });
    return row?.value ?? DEFAULT_SETTINGS[key] ?? '';
  }

  async num(key: string): Promise<number> {
    const n = Number(await this.get(key));
    return Number.isFinite(n) ? n : Number(DEFAULT_SETTINGS[key] ?? 0);
  }

  async update(values: Record<string, string>) {
    const allowed = Object.keys(DEFAULT_SETTINGS);
    for (const [key, value] of Object.entries(values)) {
      if (!allowed.includes(key)) continue;
      await this.prisma.appSetting.upsert({
        where: { key },
        update: { value: String(value) },
        create: { key, value: String(value) },
      });
    }
    return this.all();
  }
}
