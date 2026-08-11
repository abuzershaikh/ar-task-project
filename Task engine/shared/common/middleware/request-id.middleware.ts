import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
    use(req: Request, res: Response, next: NextFunction) {
        const headerValue = req.headers['x-request-id'];
        const requestId = Array.isArray(headerValue)
            ? headerValue[0]
            : headerValue || uuidv4();
        (req as any).id = requestId;
        res.setHeader('X-Request-Id', requestId);
        next();
    }
}
