import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';

@Injectable()
export class UserRepository {
    constructor(
        @InjectRepository(User)
        private readonly repository: Repository<User>,
    ) { }

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
}
