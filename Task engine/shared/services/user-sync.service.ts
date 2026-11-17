import { DataSource } from 'typeorm';
import { assertWorkerAccountNotDeleted } from './worker-deletion-guard';
import { ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { Worker } from '../database/entities/worker.entity';
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
    private readonly dataSource: DataSource,
  ) {}

  /// Ensures user exists in MySQL. If not found, fetches from Firestore ONCE and saves to MySQL.
  /// Updates last_login timestamp on MySQL user and worker records.
  async ensureUserInMySQL(emailOrId: string, preferredRole: UserRole = UserRole.WORKER): Promise<User> {
    await this.assertAccountAvailable(emailOrId);
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

        // Ensure Worker record exists in MySQL and update lastActiveAt
        if (user.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
          await this.ensureWorkerRecord(user.id);
          await this.workerRepo.updateLastActiveAt(user.id);
        }
        return user;
      }

      // 2. If user NOT in MySQL, fetch ONCE from Firestore
      this.logger.log(`User ${emailOrId} not in MySQL. Fetching from Firestore once...`);
      const firestoreUser = await this.firebaseAdminService.getFirestoreUser(emailOrId);

      resolvedEmail = firestoreUser?.email || (emailOrId.includes('@') ? emailOrId : `${emailOrId}@app.user`);
      await this.assertAccountAvailable(resolvedEmail, firestoreUser?.uid, firestoreUser?.id);
      const fullName = firestoreUser?.name || resolvedEmail.split('@')[0];
      const phone = firestoreUser?.phone || null;
      const role = firestoreUser?.role === 'BUYER' ? UserRole.BUYER : preferredRole;
      const avatarUrl = firestoreUser?.photoUrl || firestoreUser?.photoURL || firestoreUser?.avatarUrl || null;

      // 2b. Check if user already exists in MySQL with resolved email (Prevents Duplicate Entry error when emailOrId is a UID)
      user = await this.userRepo.findByEmail(resolvedEmail);
      if (user) {
        this.logger.log(`Found existing MySQL user by resolved email ${resolvedEmail} (${user.id}).`);
        const updatePayload: any = { lastLogin: now };
        if (avatarUrl && !user.avatarUrl) {
          updatePayload.avatarUrl = avatarUrl;
          user.avatarUrl = avatarUrl;
        }
        await this.userRepo.update(user.id, updatePayload);
        user.lastLogin = now;

        if (user.role === UserRole.WORKER || preferredRole === UserRole.WORKER) {
          await this.ensureWorkerRecord(user.id);
          await this.workerRepo.updateLastActiveAt(user.id);
        }
        return user;
      }

      // 3. Create user in MySQL
      user = await this.userRepo.create({
        id: firestoreUser?.uid || undefined,
        email: resolvedEmail,
        fullName,
        avatarUrl,
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
        await this.workerRepo.updateLastActiveAt(user.id);
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

  async assertAccountAvailable(...identifiers: string[]): Promise<void> {
    await assertWorkerAccountNotDeleted(this.dataSource, ...identifiers);
  }

  private async ensureWorkerRecord(userId: string): Promise<void> {
    try {
      await this.dataSource.transaction(async (manager) => {
        // Serialize creation with account deletion on the same parent row. An
        // already in-flight request must not create an orphan after cleanup.
        const users = await manager.query('SELECT id FROM users WHERE id = ? FOR UPDATE', [userId]);
        if (!users.length) throw new ForbiddenException('Worker account no longer exists');
        await assertWorkerAccountNotDeleted(manager, userId);
        const repository = manager.getRepository(Worker);
        const worker = await repository.findOne({ where: { userId } });
        if (!worker) {
          await repository.save(repository.create({ userId, status: 'active', kycStatus: 'APPROVED' }));
        }
      });
    } catch (err) {
      if (err?.code !== 'ER_DUP_ENTRY' && err?.errno !== 1062) throw err;
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
