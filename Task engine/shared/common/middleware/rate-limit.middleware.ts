import { Injectable, NestMiddleware, HttpException, HttpStatus } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

type HitWindow = {
    count: number;
    expiresAt: number;
};

@Injectable()
export class InMemoryRateLimitMiddleware implements NestMiddleware {
    private readonly windows = new Map<string, HitWindow>();
    private readonly windowMs = 15 * 60 * 1000;
    private readonly maxRequests = 300;

    use(req: Request, _res: Response, next: NextFunction) {
        if (req.method === 'OPTIONS') {
            return next();
        }

        this.pruneExpiredWindows();

        const key = `${req.ip}:${req.path}`;
        const now = Date.now();
        const existing = this.windows.get(key);

        if (!existing) {
            this.windows.set(key, { count: 1, expiresAt: now + this.windowMs });
            return next();
        }

        if (existing.count >= this.maxRequests) {
            throw new HttpException('Rate limit exceeded. Please try again later.', HttpStatus.TOO_MANY_REQUESTS);
        }

        existing.count += 1;
        this.windows.set(key, existing);
        next();
    }

    private pruneExpiredWindows() {
        const now = Date.now();

        for (const [key, window] of this.windows.entries()) {
            if (window.expiresAt <= now) {
                this.windows.delete(key);
            }
        }
    }
}
