import {
    Injectable,
    UnauthorizedException,
    BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { UserRepository } from '../database/repositories/user.repository';
import { WorkerRepository } from '../database/repositories/worker.repository';
import { User, UserRole, UserStatus } from '../database/entities/user.entity';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Injectable()
export class AuthService {
    private readonly MAX_LOGIN_ATTEMPTS = 5;
    private readonly LOCK_TIME_MINUTES = 30;
    private readonly ACCESS_TOKEN_TTL = '15m';
    private readonly REFRESH_TOKEN_TTL = '7d';
    private readonly PASSWORD_RESET_TTL_MINUTES = 60;

    constructor(
        private readonly userRepo: UserRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly jwtService: JwtService,
    ) {}

    async register(dto: RegisterDto) {
        if (dto.role !== UserRole.WORKER && dto.role !== UserRole.BUYER) {
            throw new BadRequestException('Public registration is limited to worker or buyer accounts');
        }

        const existingEmailUser = await this.userRepo.findByEmail(dto.email);
        if (existingEmailUser) {
            throw new BadRequestException('Email already registered');
        }

        if (dto.phone) {
            const existingPhoneUser = await this.userRepo.findByPhone(dto.phone);
            if (existingPhoneUser) {
                throw new BadRequestException('Phone already registered');
            }
        }

        const hashedPassword = await bcrypt.hash(dto.password, 10);

        const user = await this.userRepo.create({
            email: dto.email,
            password: hashedPassword,
            fullName: dto.fullName,
            role: dto.role,
            phone: dto.phone,
            status: UserStatus.ACTIVE,
        });

        if (dto.role === UserRole.WORKER) {
            await this.workerRepo.create({
                userId: user.id,
                status: 'inactive',
                kycStatus: 'pending',
                totalTasksCompleted: 0,
                totalTasksRejected: 0,
                successRate: 0,
                averageRating: 0,
                totalEarnings: 0,
            });
        }

        const tokens = await this.generateTokens(user);
        await this.userRepo.updateRefreshToken(
            user.id,
            await this.hashToken(tokens.refreshToken),
        );

        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }

    async login(dto: LoginDto) {
        const user = await this.userRepo.findByEmailWithPassword(dto.email);
        if (!user) {
            throw new UnauthorizedException('Invalid credentials');
        }

        this.assertAccountCanAuthenticate(user);

        if (user.lockedUntil && user.lockedUntil > new Date()) {
            const minutesLeft = Math.ceil(
                (user.lockedUntil.getTime() - Date.now()) / (1000 * 60),
            );
            throw new UnauthorizedException(
                `Account locked. Try again in ${minutesLeft} minutes`,
            );
        }

        const isPasswordValid = await bcrypt.compare(dto.password, user.password);
        if (!isPasswordValid) {
            await this.userRepo.incrementLoginAttempts(user.id);

            const attempts = (user.loginAttempts || 0) + 1;
            if (attempts >= this.MAX_LOGIN_ATTEMPTS) {
                await this.userRepo.lockAccount(user.id, this.LOCK_TIME_MINUTES);
                throw new UnauthorizedException(
                    `Account locked for ${this.LOCK_TIME_MINUTES} minutes due to multiple failed attempts`,
                );
            }

            throw new UnauthorizedException('Invalid credentials');
        }

        await this.userRepo.resetLoginAttempts(user.id);
        await this.userRepo.update(user.id, { lastLogin: new Date() });

        const tokens = await this.generateTokens(user);
        await this.userRepo.updateRefreshToken(
            user.id,
            await this.hashToken(tokens.refreshToken),
        );

        return {
            user: this.sanitizeUser(user),
            ...tokens,
        };
    }

    async refresh(dto: RefreshTokenDto) {
        try {
            const payload = this.jwtService.verify(dto.refreshToken, {
                secret: process.env.JWT_REFRESH_SECRET,
            });

            const user = await this.userRepo.findByIdWithSensitiveFields(payload.sub);
            if (!user || !user.refreshToken) {
                throw new UnauthorizedException('Invalid token');
            }

            this.assertAccountCanAuthenticate(user);

            const isTokenValid = await bcrypt.compare(dto.refreshToken, user.refreshToken);
            if (!isTokenValid) {
                throw new UnauthorizedException('Invalid token');
            }

            const tokens = await this.generateTokens(user);
            await this.userRepo.updateRefreshToken(
                user.id,
                await this.hashToken(tokens.refreshToken),
            );

            return tokens;
        } catch {
            throw new UnauthorizedException('Invalid refresh token');
        }
    }

    async logout(userId: string) {
        await this.userRepo.updateRefreshToken(userId, null);
        await this.userRepo.clearPasswordResetToken(userId);
        return { success: true, message: 'Logged out successfully' };
    }

    async getProfile(userId: string) {
        const user = await this.userRepo.findById(userId);
        if (!user) {
            throw new UnauthorizedException('User not found');
        }

        return this.sanitizeUser(user);
    }

    async forgotPassword(dto: ForgotPasswordDto) {
        const user = await this.userRepo.findByEmail(dto.email);
        if (!user) {
            return {
                message: 'If the account exists, a password reset link will be sent.',
            };
        }

        const resetToken = randomBytes(32).toString('hex');
        const resetTokenHash = await this.hashToken(resetToken);
        const expiresAt = new Date(Date.now() + this.PASSWORD_RESET_TTL_MINUTES * 60 * 1000);

        await this.userRepo.updatePasswordResetToken(user.id, resetTokenHash, expiresAt);

        return {
            message: 'If the account exists, a password reset link will be sent.',
            ...(process.env.NODE_ENV !== 'production' ? { resetToken } : {}),
        };
    }

    async resetPassword(dto: ResetPasswordDto) {
        const user = await this.userRepo.findByEmailWithSensitiveFields(dto.email);
        if (!user || !user.passwordResetTokenHash || !user.passwordResetTokenExpiresAt) {
            throw new BadRequestException('Invalid or expired reset token');
        }

        if (user.passwordResetTokenExpiresAt < new Date()) {
            throw new BadRequestException('Invalid or expired reset token');
        }

        const tokenMatches = await bcrypt.compare(dto.token, user.passwordResetTokenHash);
        if (!tokenMatches) {
            throw new BadRequestException('Invalid or expired reset token');
        }

        const hashedPassword = await bcrypt.hash(dto.newPassword, 10);
        await this.userRepo.update(user.id, { password: hashedPassword });
        await this.userRepo.updateRefreshToken(user.id, null);
        await this.userRepo.clearPasswordResetToken(user.id);

        return {
            message: 'Password reset successful',
        };
    }

    async validateUser(userId: string): Promise<User> {
        return this.userRepo.findById(userId);
    }

    private async generateTokens(user: User) {
        const payload = {
            sub: user.id,
            email: user.email,
            role: user.role,
        };

        const accessToken = this.jwtService.sign(payload, {
            secret: process.env.JWT_SECRET || 'your_secret_key',
            expiresIn: this.ACCESS_TOKEN_TTL,
        });

        const refreshToken = this.jwtService.sign(payload, {
            secret: process.env.JWT_REFRESH_SECRET || 'your_refresh_secret_key',
            expiresIn: this.REFRESH_TOKEN_TTL,
        });

        return {
            accessToken,
            refreshToken,
            expiresIn: 900,
        };
    }

    private async hashToken(token: string): Promise<string> {
        return bcrypt.hash(token, 10);
    }

    private sanitizeUser(user: User) {
        const {
            password,
            refreshToken,
            passwordResetTokenHash,
            passwordResetTokenExpiresAt,
            ...sanitized
        } = user as any;

        return sanitized;
    }

    private assertAccountCanAuthenticate(user: Pick<User, 'status' | 'role'>) {
        if (user.status !== UserStatus.ACTIVE) {
            throw new UnauthorizedException('Account is not active');
        }

        if (
            user.role !== UserRole.WORKER &&
            user.role !== UserRole.BUYER &&
            user.role !== UserRole.ADMIN &&
            user.role !== UserRole.SUPER_ADMIN
        ) {
            throw new UnauthorizedException('Invalid account role');
        }
    }
}
