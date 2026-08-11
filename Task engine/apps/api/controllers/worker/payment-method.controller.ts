import {
    Controller,
    Get,
    Post,
    Patch,
    Delete,
    Param,
    Body,
    BadRequestException,
    NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentMethodRepository } from '../../../../shared/database/repositories/payment-method.repository';
import { WorkerRepository } from '../../../../shared/database/repositories/worker.repository';
import { PaymentMethodType } from '../../../../shared/database/entities/payment-method.entity';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

@ApiTags('Worker - Payment Methods')
@Roles(UserRole.WORKER)
@ApiBearerAuth('bearer')
@Controller('worker/payment-methods')
export class WorkerPaymentMethodController {
    constructor(
        private readonly paymentMethodRepo: PaymentMethodRepository,
        private readonly workerRepo: WorkerRepository,
    ) { }

    private async getWorker(userId: string) {
        let worker = await this.workerRepo.findByUserId(userId);
        if (!worker) {
            worker = await this.workerRepo.create({ userId, status: 'active', kycStatus: 'pending' });
        }
        return worker;
    }

    private maskAccountNumber(acc: string): string {
        if (!acc || acc.length < 4) return '****';
        return 'X'.repeat(acc.length - 4) + acc.slice(-4);
    }

    private maskUpiId(upi: string): string {
        if (!upi || !upi.includes('@')) return '****@upi';
        const [handle, domain] = upi.split('@');
        const maskedHandle = handle.length > 2 ? handle.slice(0, 2) + '*'.repeat(handle.length - 2) : '**';
        return `${maskedHandle}@${domain}`;
    }

    @Get()
    @ApiOperation({ summary: 'List worker payment methods' })
    async getPaymentMethods(@CurrentUser() user: User) {
        const worker = await this.getWorker(user.id);
        const methods = await this.paymentMethodRepo.findByWorkerId(worker.id);
        return {
            success: true,
            paymentMethods: methods,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Add a new payment method (Bank / UPI)' })
    async createPaymentMethod(
        @CurrentUser() user: User,
        @Body()
        body: {
            type: PaymentMethodType;
            isDefault?: boolean;
            accountHolderName?: string;
            accountNumber?: string;
            ifscCode?: string;
            bankName?: string;
            upiId?: string;
        },
    ) {
        const worker = await this.getWorker(user.id);

        if (body.type === PaymentMethodType.BANK) {
            if (!body.accountNumber || !body.ifscCode || !body.accountHolderName) {
                throw new BadRequestException('Account number, IFSC code, and holder name are required for Bank payment methods');
            }
        } else if (body.type === PaymentMethodType.UPI) {
            if (!body.upiId) {
                throw new BadRequestException('UPI ID is required for UPI payment methods');
            }
        } else {
            throw new BadRequestException('Invalid payment method type');
        }

        if (body.isDefault) {
            await this.paymentMethodRepo.unsetDefaultsForWorker(worker.id);
        }

        const existingMethods = await this.paymentMethodRepo.findByWorkerId(worker.id);
        const shouldBeDefault = body.isDefault || existingMethods.length === 0;

        const created = await this.paymentMethodRepo.create({
            workerId: worker.id,
            type: body.type,
            isDefault: shouldBeDefault,
            isVerified: true,
            accountHolderName: body.accountHolderName,
            accountNumber: body.accountNumber,
            maskedAccountNumber: body.accountNumber ? this.maskAccountNumber(body.accountNumber) : undefined,
            ifscCode: body.ifscCode,
            bankName: body.bankName,
            upiId: body.upiId,
            maskedUpiId: body.upiId ? this.maskUpiId(body.upiId) : undefined,
        });

        return {
            success: true,
            paymentMethod: created,
            message: 'Payment method added successfully',
        };
    }

    @Patch(':id/default')
    @ApiOperation({ summary: 'Set default payment method' })
    async setDefault(
        @Param('id') methodId: string,
        @CurrentUser() user: User,
    ) {
        const worker = await this.getWorker(user.id);
        const method = await this.paymentMethodRepo.findById(methodId);

        if (!method || method.workerId !== worker.id) {
            throw new NotFoundException('Payment method not found');
        }

        await this.paymentMethodRepo.unsetDefaultsForWorker(worker.id);
        const updated = await this.paymentMethodRepo.update(methodId, { isDefault: true });

        return {
            success: true,
            paymentMethod: updated,
            message: 'Default payment method updated',
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete payment method' })
    async deletePaymentMethod(
        @Param('id') methodId: string,
        @CurrentUser() user: User,
    ) {
        const worker = await this.getWorker(user.id);
        const method = await this.paymentMethodRepo.findById(methodId);

        if (!method || method.workerId !== worker.id) {
            throw new NotFoundException('Payment method not found');
        }

        await this.paymentMethodRepo.delete(methodId);

        return {
            success: true,
            message: 'Payment method deleted successfully',
        };
    }
}
