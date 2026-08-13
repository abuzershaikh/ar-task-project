import {
    ExceptionFilter,
    Catch,
    ArgumentsHost,
    HttpException,
    HttpStatus,
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
    UnauthorizedException,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
    catch(exception: unknown, host: ArgumentsHost) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse<Response>();
        const request = ctx.getRequest<Request>();

        const status =
            exception instanceof HttpException
                ? exception.getStatus()
                : HttpStatus.INTERNAL_SERVER_ERROR;

        const message =
            exception instanceof HttpException
                ? exception.getResponse()
                : 'Internal server error';

        const normalizedMessage = this.getErrorMessage(message);

        const errorResponse = {
            success: false,
            error: {
                code: this.getErrorCode(exception),
                message: normalizedMessage,
                details: typeof message === 'object' ? message : undefined,
            },
            timestamp: new Date().toISOString(),
            requestId: (request as any).id || 'unknown',
        };

        response.status(status).json(errorResponse);
    }

    private getErrorCode(exception: unknown): string {
        if (exception instanceof BadRequestException) return 'BAD_REQUEST';
        if (exception instanceof UnauthorizedException) return 'UNAUTHORIZED';
        if (exception instanceof ForbiddenException) return 'FORBIDDEN';
        if (exception instanceof NotFoundException) return 'NOT_FOUND';
        if (exception instanceof ConflictException) return 'CONFLICT';
        if (exception instanceof HttpException && exception.getStatus() === HttpStatus.TOO_MANY_REQUESTS) return 'TOO_MANY_REQUESTS';

        if (exception instanceof HttpException) {
            const response = exception.getResponse();
            if (typeof response === 'object' && 'error' in response) {
                return (response as any).error;
            }
            return exception.constructor.name.replace('Exception', '').toUpperCase();
        }
        return 'INTERNAL_SERVER_ERROR';
    }

    private getErrorMessage(message: unknown): string {
        if (typeof message === 'string') {
            return message;
        }

        if (Array.isArray((message as any)?.message)) {
            return (message as any).message[0];
        }

        if (typeof message === 'object' && message !== null) {
            const response = message as Record<string, any>;

            if (typeof response.message === 'string') {
                return response.message;
            }

            if (Array.isArray(response.message) && response.message.length > 0) {
                return response.message[0];
            }
        }

        return 'Unexpected error';
    }
}
