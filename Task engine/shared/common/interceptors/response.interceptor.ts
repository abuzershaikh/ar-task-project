import {
    Injectable,
    NestInterceptor,
    ExecutionContext,
    CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface StandardResponse<T> {
    success: boolean;
    data: T;
    meta?: any;
    requestId: string;
    timestamp: string;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, StandardResponse<T>> {
    intercept(context: ExecutionContext, next: CallHandler): Observable<StandardResponse<T>> {
        const request = context.switchToHttp().getRequest();
        const requestId = request.id || 'unknown';

        return next.handle().pipe(
            map((data) => {
                // If response already has success field, return as is
                if (data && typeof data === 'object' && 'success' in data) {
                    return {
                        ...data,
                        requestId,
                        timestamp: new Date().toISOString(),
                    };
                }

                // Otherwise wrap in standard format
                return {
                    success: true,
                    data,
                    requestId,
                    timestamp: new Date().toISOString(),
                };
            }),
        );
    }
}
