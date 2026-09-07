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
    const rawAuthHeader = headers['authorization'] || headers['Authorization'];

    // 1. A cryptographic authorization token is strictly required.
    // No hardcoded /admin/ bypasses and no unauthenticated header spoofing.
    if (!rawAuthHeader || !rawAuthHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('No authorization token provided');
    }

    const token = rawAuthHeader.replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      throw new UnauthorizedException('Invalid authorization token');
    }

    // 2. Verify backend-issued JWT (e.g. Admin or registered worker/buyer)
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

    // 3. Verify Firebase ID Token (for mobile/web clients using Firebase Auth)
    try {
      const decodedFirebase = await this.firebaseAdminService.verifyIdToken(token);
      if (decodedFirebase && (decodedFirebase.email || decodedFirebase.uid)) {
        const rawRole = headers['x-user-role'] || (request.url.includes('/buyer/') ? 'BUYER' : 'WORKER');
        const role = String(rawRole).toUpperCase() === 'BUYER' ? UserRole.BUYER : UserRole.WORKER;
        const identifier = decodedFirebase.email || decodedFirebase.uid;

        const mysqlUser = await this.userSyncService.ensureUserInMySQL(identifier, role);
        request.user = mysqlUser;
        return true;
      }
    } catch (fbErr) {
      this.logger.warn(`Firebase token verification failed: ${fbErr.message}`);
    }

    // 4. Token validation failed
    throw new UnauthorizedException('Invalid or expired authorization token');
  }
}
