import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { map } from 'rxjs';

const toSnake = (k: string) =>
  k.replace(/[A-Z]/g, (c) => `_${c.toLowerCase()}`);

/** Respons API konsisten: key snake_case, BigInt → number, Decimal → string. */
export function normalize(v: unknown): unknown {
  if (v === null || v === undefined) return v;
  if (typeof v === 'bigint') return Number(v);
  if (v instanceof Date) return v.toISOString();
  if (Prisma.Decimal.isDecimal(v)) return v.toString();
  if (Buffer.isBuffer(v)) return v;
  if (Array.isArray(v)) return v.map(normalize);
  if (typeof v === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, val] of Object.entries(v)) {
      if (k === 'passwordHash' || k === 'tokenHash') continue;
      out[toSnake(k)] = normalize(val);
    }
    return out;
  }
  return v;
}

@Injectable()
export class SnakeCaseInterceptor implements NestInterceptor {
  intercept(_ctx: ExecutionContext, next: CallHandler) {
    return next.handle().pipe(map((data) => normalize(data)));
  }
}
