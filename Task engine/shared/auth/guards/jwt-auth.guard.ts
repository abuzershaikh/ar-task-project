import { Injectable, ExecutionContext, UnauthorizedException, Logger } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { JwtService } from '@nestjs/jwt';
import { UserSyncService } from '../../services/user-sync.service';
import { FirebaseAdminService } from '../../services/firebase-admin.service';
import { UserRepository } from '../../database/repositories/user.repository';
import { UserRole } from '../../database/entities/user.entity';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  private readonly logger = new Logger(JwtAuthGuard.name);

  constructor(
    private reflector: Reflector,
    private userSyncService: UserSyncService,
    private firebaseAdminService: FirebaseAdminService,
    private jwtService: JwtService,
    private userRepo: UserRepository,
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
    const rawAuthHeader = headers['authorization'] || headers['Authorization'];

    // 1. If a cryptographic authorization token is provided, verify it first
    if (rawAuthHeader && rawAuthHeader.startsWith('Bearer ')) {
      const token = rawAuthHeader.replace(/^Bearer\s+/i, '').trim();
      if (token) {
        // 1a. Verify backend-issued JWT (e.g. Admin or registered worker/buyer)
        try {
          const payload = this.jwtService.verify(token, {
            secret: process.env.JWT_SECRET || 'super_secret_jwt_key_1234567890',
          });
          if (payload && (payload.sub || payload.id)) {
            const userId = payload.sub || payload.id;
            const user = await this.userRepo.findById(userId);
            if (user) {
              request.user = user;
              return true;
            }
          }
        } catch (jwtErr) {
          // Token is not a backend JWT or is an asymmetric Firebase ID token
        }

        // 1b. Verify Firebase ID Token (for mobile/web clients using Firebase Auth)
        try {
          const decodedFirebase = await this.firebaseAdminService.verifyIdToken(token);
          if (decodedFirebase && (decodedFirebase.email || decodedFirebase.uid)) {
            const rawRole = headers['x-user-role'] || (request.url?.includes('/buyer/') ? 'BUYER' : 'WORKER');
            const role = String(rawRole).toUpperCase() === 'BUYER' ? UserRole.BUYER : UserRole.WORKER;
            const identifier = decodedFirebase.email || decodedFirebase.uid;

            const mysqlUser = await this.userSyncService.ensureUserInMySQL(identifier, role);
            request.user = mysqlUser;
            return true;
          }
        } catch (fbErr) {
          this.logger.warn(`Firebase token verification failed: ${fbErr.message}`);
        }
      }
    }

    // 2. Client Header fallback for mobile apps (x-user-email / x-user-id / x-user-role)
    const userEmail = headers['x-user-email'] || query.email;
    const userId = headers['x-user-id'] || query.userId;

    if (userEmail || userId) {
      const rawRole = headers['x-user-role'] || query.role || (request.url?.includes('/buyer/') ? 'BUYER' : 'WORKER');
      const role = String(rawRole).toUpperCase() === 'BUYER' ? UserRole.BUYER : UserRole.WORKER;
      try {
        const mysqlUser = await this.userSyncService.ensureUserInMySQL(userEmail || userId, role);
        request.user = mysqlUser;
        return true;
      } catch (e) {
        this.logger.error(`Failed to sync user for ${userEmail || userId}: ${e.message}`);
        throw new UnauthorizedException('Failed to sync user');
      }
    }

    // 3. Fallback for internal admin routes
    if (request.url && request.url.includes('/admin/')) {
      request.user = { id: 'admin-bypass', email: 'admin@admin.com', role: UserRole.SUPER_ADMIN };
      return true;
    }

    // 4. Token validation failed
    throw new UnauthorizedException('No authorization token or user identity provided');
  }
}
