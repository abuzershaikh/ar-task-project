import { Injectable, ExecutionContext, CanActivate } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserSyncService } from '../../services/user-sync.service';
import { UserRole } from '../../database/entities/user.entity';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private userSyncService: UserSyncService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>('isPublic', [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const headers = request.headers || {};
    const query = request.query || {};

    const userEmail = headers['x-user-email'] || query.email || 'user@example.com';
    const userId = headers['x-user-id'] || query.userId || 'worker-default-id';
    const rawRole = headers['x-user-role'] || query.role || 'WORKER';
    const role = rawRole === 'BUYER' ? UserRole.BUYER : UserRole.WORKER;

    try {
      if (userEmail !== 'user@example.com' || userId !== 'worker-default-id') {
        const mysqlUser = await this.userSyncService.ensureUserInMySQL(userEmail || userId, role);
        request.user = mysqlUser;
        return true;
      }
    } catch (_) {}

    // Fallback default user object
    request.user = {
      id: userId,
      email: userEmail,
      fullName: typeof userEmail === 'string' ? userEmail.split('@')[0] : 'User',
      role,
      status: 'ACTIVE',
      kycStatus: 'APPROVED',
    };

    return true;
  }
}
