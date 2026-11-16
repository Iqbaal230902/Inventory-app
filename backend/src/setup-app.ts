import {
  INestApplication,
  RequestMethod,
  ValidationPipe,
} from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { configureAdminViews } from './admin-panel/view-engine';

/** Konfigurasi bersama untuk main.ts dan e2e test. */
export function setupApp(app: INestApplication) {
  // REST API di /api/v1, admin panel (Handlebars) di /admin-panel pada server yang sama.
  app.setGlobalPrefix('api/v1', {
    exclude: [
      { path: 'admin-panel', method: RequestMethod.ALL },
      { path: 'admin-panel/{*path}', method: RequestMethod.ALL },
    ],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      errorHttpStatusCode: 422,
    }),
  );
  app.enableCors();
  configureAdminViews(app as NestExpressApplication);
  return app;
}
