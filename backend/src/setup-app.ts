import { INestApplication, ValidationPipe } from '@nestjs/common';

/** Konfigurasi bersama untuk main.ts dan e2e test. */
export function setupApp(app: INestApplication) {
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      errorHttpStatusCode: 422,
    }),
  );
  app.enableCors();
  return app;
}
