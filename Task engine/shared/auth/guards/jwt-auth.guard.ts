import { Injectable, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { UserSyncService } from '../../services/user-sync.service';
import { UserRole } from '../../database/entities/user.entity';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private reflector: Reflector,
    private userSyncService: UserSyncService,
  ) {
    super();
  }

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

    const userEmail = headers['x-user-email'] || query.email;
    const userId = headers['x-user-id'] || query.userId;

    if (userEmail || userId) {
      const rawRole = headers['x-user-role'] || query.role || 'WORKER';
      const role = rawRole === 'BUYER' ? UserRole.BUYER : UserRole.WORKER;
      try {
        const mysqlUser = await this.userSyncService.ensureUserInMySQL(userEmail || userId, role);
        request.user = mysqlUser;
        return true;
      } catch (e) {
        throw new UnauthorizedException('Failed to sync user');
      }
    }

    if (headers['authorization']) {
      return (await super.canActivate(context)) as boolean;
    }

    throw new UnauthorizedException('No authorization token provided');
  }
}
