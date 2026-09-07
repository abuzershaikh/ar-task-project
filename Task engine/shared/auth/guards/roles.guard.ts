import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../database/entities/user.entity';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        const isPublic = this.reflector.getAllAndOverride<boolean>('isPublic', [
            context.getHandler(),
            context.getClass(),
        ]);

        if (isPublic) {
            return true;
        }

        const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>('roles', [
            context.getHandler(),
            context.getClass(),
        ]);

        if (!requiredRoles || requiredRoles.length === 0) {
            return true;
        }

        const request = context.switchToHttp().getRequest();
        const user = request.user;

        if (!user) {
            throw new ForbiddenException('User not authenticated');
        }

        // 1. Super Admin & Admin have universal permission access across all routes
        if (user.role === UserRole.SUPER_ADMIN || user.role === UserRole.ADMIN) {
            return true;
        }

        // 2. Direct exact role match
        const hasRole = requiredRoles.some((role) => user.role === role);
        if (hasRole) {
            return true;
        }

        throw new ForbiddenException(`Insufficient permissions. Required: ${requiredRoles.join(',')}, Got: ${user.role} (User: ${user.email})`);
    }
}

