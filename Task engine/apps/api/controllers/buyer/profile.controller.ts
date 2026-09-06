import { Controller, Get, Patch, Put, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

export interface UpdateBuyerProfileDto {
    fullName?: string;
    name?: string;
    phone?: string;
    companyName?: string;
    website?: string;
    gstNumber?: string;
    bio?: string;
    avatarUrl?: string;
    billingAddress?: string;
    industry?: string;
    notificationPreferences?: any;
}

@ApiTags('Buyer - Profile')
@Roles(UserRole.BUYER)
@ApiBearerAuth('bearer')
@Controller('buyer/profile')
export class BuyerProfileController {
    constructor(
        private readonly userRepo: UserRepository,
        private readonly orderRepo: OrderRepository,
    ) { }

    @Get()
    @ApiOperation({ summary: 'Get buyer profile and account details' })
    async getProfile(@CurrentUser() user: User) {
        const freshUser = await this.userRepo.findById(user.id) || user;
        const orders = await this.orderRepo.findByBuyer(user.id);

        const totalSpend = orders.reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);
        const activeOrdersCount = orders.filter(o => o.status === 'ACTIVE' || o.status === 'IN_PROGRESS').length;
        const completedOrdersCount = orders.filter(o => o.status === 'COMPLETED').length;

        const metadata = freshUser.metadata || {};
        const profileData = {
            id: freshUser.id,
            fullName: freshUser.fullName || 'Buyer Account',
            name: freshUser.fullName || 'Buyer Account',
            email: freshUser.email,
            phone: freshUser.phone || '',
            companyName: metadata.companyName || '',
            website: metadata.website || '',
            gstNumber: metadata.gstNumber || '',
            bio: metadata.bio || '',
            avatarUrl: metadata.avatarUrl || '',
            billingAddress: metadata.billingAddress || '',
            industry: metadata.industry || 'Technology & E-Commerce',
            notificationPreferences: metadata.notificationPreferences || {
                campaignUpdates: true,
                taskProofs: true,
                walletAlerts: true,
                promotions: false,
            },
            role: freshUser.role,
            status: freshUser.status,
            createdAt: freshUser.createdAt,
            totalOrdersCount: orders.length,
            activeOrdersCount,
            completedOrdersCount,
            totalSpend,
        };

        return {
            success: true,
            profile: profileData,
            buyer: profileData,
            user: profileData,
        };
    }

    @Patch()
    @ApiOperation({ summary: 'Update buyer profile details (PATCH)' })
    async updateProfilePatch(
        @CurrentUser() user: User,
        @Body() body: UpdateBuyerProfileDto,
    ) {
        return this.handleProfileUpdate(user, body);
    }

    @Put()
    @ApiOperation({ summary: 'Update buyer profile details (PUT)' })
    async updateProfilePut(
        @CurrentUser() user: User,
        @Body() body: UpdateBuyerProfileDto,
    ) {
        return this.handleProfileUpdate(user, body);
    }

    @Get('invoices')
    @ApiOperation({ summary: 'Get buyer invoices and billing receipts' })
    async getInvoices(@CurrentUser() user: User) {
        const orders = await this.orderRepo.findByBuyer(user.id);
        const invoices = orders.map((o) => {
            const amount = Number(o.totalAmount || (o.rewardPerTask * o.totalTasksRequired) || 0);
            return {
                id: `INV-${o.id.substring(0, 8).toUpperCase()}`,
                orderId: o.id,
                campaignTitle: o.title,
                taskType: o.taskType,
                amount,
                date: o.createdAt,
                status: o.status === 'CANCELLED' ? 'REFUNDED' : 'PAID',
                pdfUrl: `/buyer/invoices/download/${o.id}`,
                gstAmount: Number((amount * 0.18).toFixed(2)),
            };
        });

        return {
            success: true,
            invoices,
        };
    }

    private async handleProfileUpdate(user: User, body: UpdateBuyerProfileDto) {
        const freshUser = await this.userRepo.findById(user.id) || user;
        const currentMetadata = freshUser.metadata || {};

        const updatedMetadata = {
            ...currentMetadata,
            companyName: body.companyName !== undefined ? body.companyName : (currentMetadata.companyName || ''),
            website: body.website !== undefined ? body.website : (currentMetadata.website || ''),
            gstNumber: body.gstNumber !== undefined ? body.gstNumber : (currentMetadata.gstNumber || ''),
            bio: body.bio !== undefined ? body.bio : (currentMetadata.bio || ''),
            avatarUrl: body.avatarUrl !== undefined ? body.avatarUrl : (currentMetadata.avatarUrl || ''),
            billingAddress: body.billingAddress !== undefined ? body.billingAddress : (currentMetadata.billingAddress || ''),
            industry: body.industry !== undefined ? body.industry : (currentMetadata.industry || ''),
            notificationPreferences: body.notificationPreferences !== undefined ? body.notificationPreferences : (currentMetadata.notificationPreferences || {}),
        };

        const newFullName = body.fullName || body.name || freshUser.fullName;
        const newPhone = body.phone !== undefined ? body.phone : freshUser.phone;

        await this.userRepo.update(user.id, {
            fullName: newFullName,
            phone: newPhone,
            metadata: updatedMetadata,
        });

        const updatedUser = await this.userRepo.findById(user.id) || freshUser;
        const orders = await this.orderRepo.findByBuyer(user.id);

        const totalSpend = orders.reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);
        const activeOrdersCount = orders.filter(o => o.status === 'ACTIVE' || o.status === 'IN_PROGRESS').length;
        const completedOrdersCount = orders.filter(o => o.status === 'COMPLETED').length;

        const profileData = {
            id: updatedUser.id,
            fullName: updatedUser.fullName,
            name: updatedUser.fullName,
            email: updatedUser.email,
            phone: updatedUser.phone || '',
            companyName: updatedMetadata.companyName,
            website: updatedMetadata.website,
            gstNumber: updatedMetadata.gstNumber,
            bio: updatedMetadata.bio,
            avatarUrl: updatedMetadata.avatarUrl,
            billingAddress: updatedMetadata.billingAddress,
            industry: updatedMetadata.industry,
            notificationPreferences: updatedMetadata.notificationPreferences,
            role: updatedUser.role,
            status: updatedUser.status,
            createdAt: updatedUser.createdAt,
            totalOrdersCount: orders.length,
            activeOrdersCount,
            completedOrdersCount,
            totalSpend,
        };

        return {
            success: true,
            profile: profileData,
            buyer: profileData,
            user: profileData,
            message: 'Profile updated successfully',
        };
    }
}
