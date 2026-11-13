import { HttpException, HttpStatus } from '@nestjs/common';

/** Error bisnis dengan format standar PRD: { error: { code, message, details } } */
export class AppError extends HttpException {
  constructor(
    public readonly code: string,
    message: string,
    status: number = HttpStatus.UNPROCESSABLE_ENTITY,
    public readonly details?: unknown,
  ) {
    super({ error: { code, message, details } }, status);
  }

  static forbidden(message = 'Anda tidak memiliki izin untuk aksi ini.') {
    return new AppError('FORBIDDEN', message, HttpStatus.FORBIDDEN);
  }

  static notFound(message = 'Data tidak ditemukan.') {
    return new AppError('NOT_FOUND', message, HttpStatus.NOT_FOUND);
  }

  static validation(message: string, details?: unknown) {
    return new AppError(
      'VALIDATION_ERROR',
      message,
      HttpStatus.UNPROCESSABLE_ENTITY,
      details,
    );
  }

  static unauthenticated(message = 'Sesi berakhir, silakan login kembali.') {
    return new AppError('UNAUTHENTICATED', message, HttpStatus.UNAUTHORIZED);
  }
}
