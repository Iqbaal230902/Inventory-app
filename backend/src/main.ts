import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { setupApp } from './setup-app';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.set('trust proxy', 1);
  app.useBodyParser('json', { limit: '2mb' });
  setupApp(app);
  const port = Number(process.env.PORT ?? 3000);
  // Di server produksi set HOST=127.0.0.1 agar hanya bisa diakses lewat reverse proxy (nginx).
  await app.listen(port, process.env.HOST ?? '0.0.0.0');
  Logger.log(`API berjalan di http://localhost:${port}/api/v1`, 'Bootstrap');
}
void bootstrap();
