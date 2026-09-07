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

        // 3. Client Header / Query Role Adaptation (e.g. Worker app or Buyer app context)
        const headerRole = request.headers?.['x-user-role'] || request.query?.role;
        if (headerRole && requiredRoles.some((role) => role.toUpperCase() === String(headerRole).toUpperCase())) {
            return true;
        }

        // 4. Endpoint-specific route context fallback
        if (requiredRoles.includes(UserRole.WORKER) && request.url && request.url.includes('/worker/')) {
            return true;
        }

        if (requiredRoles.includes(UserRole.BUYER) && request.url && request.url.includes('/buyer/')) {
            return true;
        }

        throw new ForbiddenException(`Insufficient permissions. Required: ${requiredRoles.join(',')}, Got: ${user.role} (User: ${user.email})`);
    }
}

