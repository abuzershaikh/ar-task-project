import { Controller, Get, Patch, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UserRepository } from '../../../../shared/database/repositories/user.repository';
import { OrderRepository } from '../../../../shared/database/repositories/order.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { UserRole, User } from '../../../../shared/database/entities/user.entity';

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
        const orders = await this.orderRepo.findByBuyer(user.id);

        return {
            success: true,
            buyer: {
                id: user.id,
                fullName: user.fullName,
                email: user.email,
                phone: user.phone,
                role: user.role,
                status: user.status,
                createdAt: user.createdAt,
                totalOrdersCount: orders.length,
            },
        };
    }

    @Patch()
    @ApiOperation({ summary: 'Update buyer profile details' })
    async updateProfile(
        @CurrentUser() user: User,
        @Body() body: { fullName?: string; phone?: string },
    ) {
        const updated = await this.userRepo.update(user.id, {
            fullName: body.fullName || user.fullName,
            phone: body.phone || user.phone,
        });

        return {
            success: true,
            user: updated,
            message: 'Profile updated successfully',
        };
    }
}
