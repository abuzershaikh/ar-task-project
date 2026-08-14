import { ValidationPipe, Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from '../../shared/common/filters/http-exception.filter';
import { ResponseInterceptor } from '../../shared/common/interceptors/response.interceptor';
import { RequestIdMiddleware } from '../../shared/common/middleware/request-id.middleware';
import { RequestLoggingMiddleware } from '../../shared/common/middleware/request-logging.middleware';
import { SecurityHeadersMiddleware } from '../../shared/common/middleware/security-headers.middleware';
import { JwtAuthGuard } from '../../shared/auth/guards/jwt-auth.guard';
import { RolesGuard } from '../../shared/auth/guards/roles.guard';

async function bootstrap() {
    const app = await NestFactory.create(AppModule, {
        logger: ['error', 'warn', 'log', 'debug', 'verbose'],
    });

    const logger = new Logger('Bootstrap');
    const requestIdMiddleware = new RequestIdMiddleware();
    const loggingMiddleware = new RequestLoggingMiddleware();
    const securityHeadersMiddleware = new SecurityHeadersMiddleware();

    app.use(json({ limit: '1mb' }));
    app.use(urlencoded({ extended: true, limit: '1mb' }));

    app.use((req, res, next) => requestIdMiddleware.use(req, res, next));
    app.use((req, res, next) => securityHeadersMiddleware.use(req, res, next));
    app.use((req, res, next) => loggingMiddleware.use(req, res, next));
    // Rate limiting is handled by Nginx in production to support multi-process PM2

    const allowedOrigins = process.env.CORS_ORIGINS 
        ? process.env.CORS_ORIGINS.split(',') 
        : [
            'http://localhost:3000', 
            'http://localhost:5173', // Vite default
            'http://localhost:8080'
          ]; // Default fallback for local dev if env not set

    app.enableCors({
        origin: (origin, callback) => {
            if (!origin || allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
                callback(null, true);
            } else {
                callback(new Error('Not allowed by CORS'));
            }
        },
        credentials: true,
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
        exposedHeaders: ['X-Request-Id'],
    });

    app.setGlobalPrefix('api/v1');

    app.useGlobalPipes(
        new ValidationPipe({
            whitelist: true,
            transform: true,
            forbidNonWhitelisted: true,
            transformOptions: {
                enableImplicitConversion: true,
            },
        }),
    );

    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(new ResponseInterceptor());
    app.useGlobalGuards(app.get(JwtAuthGuard), app.get(RolesGuard));

    const swaggerConfig = new DocumentBuilder()
        .setTitle('Task Platform API')
        .setDescription('Enterprise Task Platform backend APIs')
        .setVersion('1.0')
        .addBearerAuth(
            {
                type: 'http',
                scheme: 'bearer',
                bearerFormat: 'JWT',
            },
            'bearer',
        )
        .build();

    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document, {
        swaggerOptions: {
            persistAuthorization: true,
        },
    });

    const port = Number(process.env.PORT || 3000);
    await app.listen(port, '0.0.0.0');

    logger.log(`API server running on http://localhost:${port}`);
    logger.log(`Swagger docs available at http://localhost:${port}/api/docs`);
}

bootstrap();
