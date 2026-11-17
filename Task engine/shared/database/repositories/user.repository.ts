import { BadRequestException, Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { assertWorkerAccountNotDeleted } from '../../services/worker-deletion-guard';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';

@Injectable()
export class UserRepository {
    constructor(
        @InjectRepository(User)
        private readonly repository: Repository<User>,
    ) { }

    async claimWorkerDeviceToken(userId: string, token: string): Promise<void> {
        if (typeof token !== 'string' || token.trim() !== token || token.length < 21 || token.length > 4096) {
            throw new BadRequestException('Invalid device token');
        }
        const runner = this.repository.manager.connection.createQueryRunner();
        const lock = `push_owner_${createHash('sha256').update(token).digest('hex').slice(0, 48)}`;
        let locked = false;
        await runner.connect();
        try {
            const result = await runner.query('SELECT GET_LOCK(?, 10) AS acquired', [lock]);
            locked = Number(result?.[0]?.acquired) === 1;
            if (!locked) throw new BadRequestException('Device registration is busy. Please retry.');
            await runner.startTransaction();
            const users = await runner.query("SELECT id FROM users WHERE id = ? AND role = 'WORKER' FOR UPDATE", [userId]);
            if (!users.length) throw new BadRequestException('Worker account no longer exists');
            await assertWorkerAccountNotDeleted(runner, userId);
            await runner.query(`UPDATE users SET metadata = CASE
                WHEN JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.fcmToken')) = ?
                 AND JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.deviceToken')) = ?
                    THEN JSON_REMOVE(metadata, '$.fcmToken', '$.deviceToken')
                WHEN JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.fcmToken')) = ?
                    THEN JSON_REMOVE(metadata, '$.fcmToken')
                ELSE JSON_REMOVE(metadata, '$.deviceToken') END
                WHERE role = 'WORKER' AND id <> ? AND
                (JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.fcmToken')) = ?
                 OR JSON_UNQUOTE(JSON_EXTRACT(metadata, '$.deviceToken')) = ?)`,
            [token, token, token, userId, token, token]);
            await runner.query(`UPDATE users SET metadata = JSON_SET(COALESCE(metadata, JSON_OBJECT()),
                '$.fcmToken', ?, '$.deviceToken', ?, '$.tokenUpdatedAt', ?) WHERE id = ?`,
            [token, token, new Date().toISOString(), userId]);
            await runner.commitTransaction();
        } catch (error) {
            if (runner.isTransactionActive) await runner.rollbackTransaction();
            throw error;
        } finally {
            try {
                if (locked) await runner.query('SELECT RELEASE_LOCK(?)', [lock]);
            } finally {
                await runner.release();
            }
        }
    }

    async findById(id: string): Promise<User | null> {
        return this.repository.findOne({ where: { id } });
    }

    async findByIdWithSensitiveFields(id: string): Promise<User | null> {
        return this.repository
            .createQueryBuilder('user')
            .where('user.id = :id', { id })
            .addSelect('user.password')
            .addSelect('user.refreshToken')
            .addSelect('user.passwordResetTokenHash')
            .getOne();
    }

    async findByEmail(email: string): Promise<User | null> {
        return this.repository.findOne({ where: { email } });
    }

    async findByEmailWithPassword(email: string): Promise<User | null> {
        return this.repository
            .createQueryBuilder('user')
            .where('user.email = :email', { email })
            .addSelect('user.password')
            .addSelect('user.refreshToken')
            .addSelect('user.passwordResetTokenHash')
            .addSelect('user.passwordResetTokenExpiresAt')
            .getOne();
    }

    async findByEmailWithSensitiveFields(email: string): Promise<User | null> {
        return this.repository
            .createQueryBuilder('user')
            .where('user.email = :email', { email })
            .addSelect('user.password')
            .addSelect('user.refreshToken')
            .addSelect('user.passwordResetTokenHash')
            .addSelect('user.passwordResetTokenExpiresAt')
            .getOne();
    }

    async findByPhone(phone: string): Promise<User | null> {
        return this.repository.findOne({ where: { phone } });
    }

    async create(data: Partial<User>): Promise<User> {
        const user = this.repository.create(data);
        return this.repository.save(user);
    }

    async update(id: string, data: Partial<User>): Promise<User> {
        await this.repository.update(id, data);
        return this.findById(id);
    }

    async updateRefreshToken(userId: string, refreshToken: string | null): Promise<void> {
        await this.repository.update(userId, { refreshToken });
    }

    async updatePasswordResetToken(
        userId: string,
        passwordResetTokenHash: string | null,
        passwordResetTokenExpiresAt: Date | null,
    ): Promise<void> {
        await this.repository.update(userId, {
            passwordResetTokenHash,
            passwordResetTokenExpiresAt,
        });
    }

    async clearPasswordResetToken(userId: string): Promise<void> {
        await this.repository.update(userId, {
            passwordResetTokenHash: null,
            passwordResetTokenExpiresAt: null,
        });
    }

    async incrementLoginAttempts(userId: string): Promise<void> {
        await this.repository.increment({ id: userId }, 'loginAttempts', 1);
    }

    async resetLoginAttempts(userId: string): Promise<void> {
        await this.repository.update(userId, { loginAttempts: 0, lockedUntil: null });
    }

    async lockAccount(userId: string, minutes: number): Promise<void> {
        const lockedUntil = new Date();
        lockedUntil.setMinutes(lockedUntil.getMinutes() + minutes);

        await this.repository.update(userId, { lockedUntil });
    }

    async findByRole(role: any): Promise<User[]> {
        return this.repository.find({ where: { role } });
    }

    async updateStatus(id: string, status: any): Promise<void> {
        await this.repository.update(id, { status });
    }

    async delete(id: string): Promise<void> {
        await this.repository.delete(id);
    }
}
