import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AuditLogService } from '../../../../shared/services/audit-log.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Audit Logs')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/audit-logs')
export class AdminAuditLogController {
    constructor(private readonly auditLogService: AuditLogService) { }

    @Get()
    @ApiOperation({ summary: 'Query central append-only audit trail' })
    @ApiQuery({ name: 'actorId', required: false })
    @ApiQuery({ name: 'entityType', required: false })
    @ApiQuery({ name: 'entityId', required: false })
    @ApiQuery({ name: 'action', required: false })
    @ApiQuery({ name: 'page', required: false })
    @ApiQuery({ name: 'limit', required: false })
    async getAuditLogs(
        @Query('actorId') actorId?: string,
        @Query('entityType') entityType?: string,
        @Query('entityId') entityId?: string,
        @Query('action') action?: string,
        @Query('page') page?: number,
        @Query('limit') limit?: number,
    ) {
        const result = await this.auditLogService.getLogs({
            actorId,
            entityType,
            entityId,
            action,
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 20,
        });

        return {
            success: true,
            items: result.items,
            total: result.total,
            page: page || 1,
            limit: limit || 20,
        };
    }
}
