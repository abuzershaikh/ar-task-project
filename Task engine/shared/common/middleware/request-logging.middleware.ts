import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class RequestLoggingMiddleware implements NestMiddleware {
    private readonly logger = new Logger(RequestLoggingMiddleware.name);

    use(req: Request, res: Response, next: NextFunction) {
        const startedAt = Date.now();
        const requestId = (req as any).id || req.headers['x-request-id'] || 'unknown';

        res.on('finish', () => {
            const durationMs = Date.now() - startedAt;
            this.logger.log(
                `${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs}ms requestId=${requestId}`,
            );
        });

        next();
    }
}
