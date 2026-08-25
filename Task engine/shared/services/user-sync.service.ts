import { Injectable, Logger } from '@nestjs/common';
import { UserRepository } from '../database/repositories/user.repository';
import { WorkerRepository } from '../database/repositories/worker.repository';
import { UserRole, UserStatus, User } from '../database/entities/user.entity';
import { FirebaseAdminService } from './firebase-admin.service';

@Injectable()
export class UserSyncService {
  private readonly logger = new Logger(UserSyncService.name);

  constructor(
    private readonly userRepo: UserRepository,
    private readonly workerRepo: WorkerRepository,
    private readonly firebaseAdminService: FirebaseAdminService,
  ) {}

  /// Ensures user exists in MySQL. If not found, fetches from Firestore ONCE and saves to MySQL.
  /// Updates last_login timestamp on MySQL user and worker records.
  async ensureUserInMySQL(emailOrId: string, preferredRole: UserRole = UserRole.WORKER): Promise<User> {
    try {
      // 1. Search MySQL by email or ID first (Fast lookup)
      let user = await this.userRepo.findByEmail(emailOrId);
      if (!user) {
        user = await this.userRepo.findById(emailOrId);
      }

      const now = new Date();

      if (user) {
        // Update last login timestamp in MySQL
        await this.userRepo.update(user.id, { lastLogin: now });
        user.lastLogin = now;

        // Ensure Worker record exists in MySQL if user is a WORKER or accessing as WORKER
        if (user.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
          let worker = await this.workerRepo.findByUserId(user.id);
          if (!worker) {
            await this.workerRepo.create({
              userId: user.id,
              status: 'active',
              kycStatus: 'APPROVED',
            });
          }
        }
        return user;
      }

      // 2. If user NOT in MySQL, fetch ONCE from Firestore
      this.logger.log(`User ${emailOrId} not in MySQL. Fetching from Firestore once...`);
      const firestoreUser = await this.firebaseAdminService.getFirestoreUser(emailOrId);

      const email = firestoreUser?.email || (emailOrId.includes('@') ? emailOrId : `${emailOrId}@app.user`);
      const fullName = firestoreUser?.name || email.split('@')[0];
      const phone = firestoreUser?.phone || null;
      const role = firestoreUser?.role === 'BUYER' ? UserRole.BUYER : preferredRole;

      // 3. Create user in MySQL
      user = await this.userRepo.create({
        id: firestoreUser?.uid || undefined,
        email,
        fullName,
        phone,
        password: 'FIREBASE_AUTH_USER',
        role,
        status: UserStatus.ACTIVE,
        lastLogin: now,
      });

      this.logger.log(`Successfully synced user ${email} (${user.id}) into MySQL.`);

      // 4. Create Worker record in MySQL if WORKER
      if (role === UserRole.WORKER) {
        await this.workerRepo.create({
          userId: user.id,
          status: 'active',
          kycStatus: 'APPROVED',
        });
      }

      return user;
    } catch (error) {
      this.logger.error(`Error in ensureUserInMySQL for ${emailOrId}`, error);
      throw error;
    }
  }

  /// Ping last online status for worker
  async pingLastOnline(emailOrId: string): Promise<{ success: boolean; lastOnline: Date }> {
    const user = await this.ensureUserInMySQL(emailOrId);
    return {
      success: true,
      lastOnline: user.lastLogin || new Date(),
    };
  }
}
