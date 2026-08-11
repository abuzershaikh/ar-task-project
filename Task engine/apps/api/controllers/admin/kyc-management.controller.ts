import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { KycRepository } from '../../../../shared/database/repositories/kyc.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { KycStatus } from '../../../../shared/database/entities/kyc.entity';
import { NotificationService } from '../../../../shared/services/notification.service';
import { NotificationType } from '../../../../shared/database/entities/notification.entity';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - KYC Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/kyc')
export class AdminKycManagementController {
    constructor(
        private readonly kycRepo: KycRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly notificationService: NotificationService,
    ) { }

    @Get('pending')
    @ApiOperation({ summary: 'List pending KYC verification applications' })
    async getPendingKyc() {
        const pending = await this.kycRepo.findPending();
        return {
            success: true,
            applications: pending,
            count: pending.length,
        };
    }

    @Post(':kycId/verify')
    @ApiOperation({ summary: 'Verify worker KYC application' })
    async verifyKyc(@Param('kycId') kycId: string, @CurrentUser() user: User) {
        const kyc = await this.kycRepo.findById(kycId);
        if (!kyc) {
            throw new NotFoundException('KYC application not found');
        }

        const updated = await this.kycRepo.update(kycId, {
            status: KycStatus.VERIFIED,
            reviewedBy: user.id,
            reviewedAt: new Date(),
        });

        const worker = await this.workerRepo.findById(kyc.workerId);
        if (worker) {
            await this.workerRepo.update(worker.id, { kycStatus: KycStatus.VERIFIED });

            await this.notificationService.send({
                userId: worker.userId,
                type: NotificationType.KYC_APPROVED,
                title: 'KYC Verified',
                message: 'Your KYC profile has been verified successfully. You can now accept high-value tasks!',
            });
        }

        return {
            success: true,
            kyc: updated,
            message: 'KYC application verified',
        };
    }

    @Post(':kycId/reject')
    @ApiOperation({ summary: 'Reject worker KYC application' })
    async rejectKyc(
        @Param('kycId') kycId: string,
        @Body() body: { reason: string },
        @CurrentUser() user: User,
    ) {
        const kyc = await this.kycRepo.findById(kycId);
        if (!kyc) {
            throw new NotFoundException('KYC application not found');
        }

        const updated = await this.kycRepo.update(kycId, {
            status: KycStatus.REJECTED,
            rejectionReason: body.reason || 'Documents failed validation',
            reviewedBy: user.id,
            reviewedAt: new Date(),
        });

        const worker = await this.workerRepo.findById(kyc.workerId);
        if (worker) {
            await this.workerRepo.update(worker.id, { kycStatus: KycStatus.REJECTED });

            await this.notificationService.send({
                userId: worker.userId,
                type: NotificationType.KYC_REJECTED,
                title: 'KYC Rejected',
                message: `Your KYC profile was rejected: ${body.reason || 'Documents failed validation'}`,
            });
        }

        return {
            success: true,
            kyc: updated,
            message: 'KYC application rejected',
        };
    }
}
