import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();

  // Compatibility alias: allow requests coming as /notes-api/v1/*
  // in addition to the native /v1/* routes.
  app.use((req: { url: string }, _res: unknown, next: () => void) => {
    if (req.url === '/notes-api/v1') {
      req.url = '/v1';
    } else if (req.url.startsWith('/notes-api/v1/')) {
      req.url = req.url.replace('/notes-api', '');
    }
    next();
  });

  app.setGlobalPrefix('v1');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
}

bootstrap();


