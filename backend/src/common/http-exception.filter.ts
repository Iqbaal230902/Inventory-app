import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Response } from 'express';

const DEFAULT_CODES: Record<number, [string, string]> = {
  400: ['BAD_REQUEST', 'Permintaan tidak valid.'],
  401: ['UNAUTHENTICATED', 'Sesi berakhir, silakan login kembali.'],
  403: ['FORBIDDEN', 'Anda tidak memiliki izin untuk aksi ini.'],
  404: ['NOT_FOUND', 'Data tidak ditemukan.'],
  409: ['CONFLICT', 'Data bentrok dengan data lain.'],
  413: ['PAYLOAD_TOO_LARGE', 'Ukuran data terlalu besar.'],
  422: ['VALIDATION_ERROR', 'Data yang dikirim tidak valid.'],
  429: ['TOO_MANY_REQUESTS', 'Terlalu banyak percobaan, coba lagi nanti.'],
};

/** Semua error dikembalikan dalam format { error: { code, message, details } } berbahasa Indonesia. */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('Error');

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse() as any;
      if (body && typeof body === 'object' && body.error?.code) {
        return res.status(status).json(body);
      }
      const [code, fallback] = DEFAULT_CODES[status] ?? [
        'ERROR',
        'Terjadi kesalahan.',
      ];
      // ValidationPipe menghasilkan array pesan
      const details = Array.isArray(body?.message) ? body.message : undefined;
      const message = details?.length ? `${fallback} ${details[0]}` : fallback;
      return res.status(status).json({ error: { code, message, details } });
    }

    if (
      exception instanceof Prisma.PrismaClientKnownRequestError &&
      exception.code === 'P2002'
    ) {
      return res.status(HttpStatus.CONFLICT).json({
        error: {
          code: 'CONFLICT',
          message: 'Data dengan nilai unik yang sama sudah ada.',
          details: exception.meta,
        },
      });
    }
    if (
      exception instanceof Prisma.PrismaClientKnownRequestError &&
      exception.code === 'P2025'
    ) {
      return res.status(HttpStatus.NOT_FOUND).json({
        error: { code: 'NOT_FOUND', message: 'Data tidak ditemukan.' },
      });
    }

    this.logger.error(exception instanceof Error ? exception.stack : exception);
    return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Terjadi kesalahan pada server. Silakan coba lagi.',
      },
    });
  }
}
