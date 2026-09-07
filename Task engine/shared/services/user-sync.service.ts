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
    let resolvedEmail: string | null = null;
    const now = new Date();

    try {
      // 1. Search MySQL by email or ID first (Fast lookup)
      let user = await this.userRepo.findByEmail(emailOrId);
      if (!user) {
        user = await this.userRepo.findById(emailOrId);
      }

      if (user) {
        // Update last login timestamp in MySQL
        await this.userRepo.update(user.id, { lastLogin: now });
        user.lastLogin = now;

        // Ensure Worker record exists in MySQL if user is a WORKER or accessing as WORKER
        if (user.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
          await this.ensureWorkerRecord(user.id);
        }
        return user;
      }

      // 2. If user NOT in MySQL, fetch ONCE from Firestore
      this.logger.log(`User ${emailOrId} not in MySQL. Fetching from Firestore once...`);
      const firestoreUser = await this.firebaseAdminService.getFirestoreUser(emailOrId);

      resolvedEmail = firestoreUser?.email || (emailOrId.includes('@') ? emailOrId : `${emailOrId}@app.user`);
      const fullName = firestoreUser?.name || resolvedEmail.split('@')[0];
      const phone = firestoreUser?.phone || null;
      const role = firestoreUser?.role === 'BUYER' ? UserRole.BUYER : preferredRole;

      // 2b. Check if user already exists in MySQL with resolved email (Prevents Duplicate Entry error when emailOrId is a UID)
      user = await this.userRepo.findByEmail(resolvedEmail);
      if (user) {
        this.logger.log(`Found existing MySQL user by resolved email ${resolvedEmail} (${user.id}).`);
        await this.userRepo.update(user.id, { lastLogin: now });
        user.lastLogin = now;

        if (user.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
          await this.ensureWorkerRecord(user.id);
        }
        return user;
      }

      // 3. Create user in MySQL
      user = await this.userRepo.create({
        id: firestoreUser?.uid || undefined,
        email: resolvedEmail,
        fullName,
        phone,
        password: 'FIREBASE_AUTH_USER',
        role,
        status: UserStatus.ACTIVE,
        lastLogin: now,
      });

      this.logger.log(`Successfully synced user ${resolvedEmail} (${user.id}) into MySQL.`);

      // 4. Create Worker record in MySQL if WORKER
      if (role === UserRole.WORKER) {
        await this.ensureWorkerRecord(user.id);
      }

      return user;
    } catch (error) {
      const isDuplicate =
        error?.message?.includes('Duplicate entry') ||
        error?.code === 'ER_DUP_ENTRY' ||
        error?.errno === 1062;

      if (isDuplicate) {
        this.logger.warn(`Duplicate entry handled for ${emailOrId} / ${resolvedEmail}. Retrieving existing record.`);

        // Extract duplicate key value from MySQL error message if possible
        const match = error?.message?.match(/Duplicate entry '([^']+)'/);
        const dupKey = match ? match[1] : null;

        const existing =
          (resolvedEmail ? await this.userRepo.findByEmail(resolvedEmail) : null) ||
          (dupKey ? await this.userRepo.findByEmail(dupKey) : null) ||
          (await this.userRepo.findByEmail(emailOrId)) ||
          (await this.userRepo.findById(emailOrId));

        if (existing) {
          if (existing.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
            await this.ensureWorkerRecord(existing.id);
          }
          return existing;
        }
      }
      this.logger.error(`Error in ensureUserInMySQL for ${emailOrId}`, error);
      throw error;
    }
  }

  private async ensureWorkerRecord(userId: string): Promise<void> {
    try {
      const worker = await this.workerRepo.findByUserId(userId);
      if (!worker) {
        await this.workerRepo.create({
          userId,
          status: 'active',
          kycStatus: 'APPROVED',
        });
      }
    } catch (err) {
      // Safe ignore for concurrent worker creation
      this.logger.debug(`Worker record for ${userId} already created concurrently`);
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
