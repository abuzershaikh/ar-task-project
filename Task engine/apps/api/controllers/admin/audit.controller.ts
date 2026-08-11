import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AuditLogRepository } from '../../../../shared/database/repositories/audit-log.repository';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Audit Trail')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/audit')
export class AdminAuditController {
    constructor(private readonly auditLogRepo: AuditLogRepository) { }

    @Get()
    @ApiOperation({ summary: 'Get overall platform audit trail logs' })
    @ApiQuery({ name: 'action', required: false })
    async getAuditLogs(@Query('action') action?: string) {
        if (action) {
            const logs = await this.auditLogRepo.findByAction(action);
            return { success: true, logs, total: logs.length };
        }

        const logs = await this.auditLogRepo.findRecent(100);
        return { success: true, logs, total: logs.length };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get audit log details by ID' })
    async getAuditLogById(@Param('id') id: string) {
        const log = await this.auditLogRepo.findById(id);
        return { success: true, log };
    }

    @Get('workers/:id')
    @ApiOperation({ summary: 'Get audit trail for specific worker' })
    async getWorkerAudit(@Param('id') workerId: string) {
        const logs = await this.auditLogRepo.findByTarget('WORKER', workerId);
        return { success: true, workerId, logs, total: logs.length };
    }

    @Get('buyers/:id')
    @ApiOperation({ summary: 'Get audit trail for specific buyer' })
    async getBuyerAudit(@Param('id') buyerId: string) {
        const logs = await this.auditLogRepo.findByTarget('BUYER', buyerId);
        return { success: true, buyerId, logs, total: logs.length };
    }

    @Get('orders/:id')
    @ApiOperation({ summary: 'Get audit trail for specific order' })
    async getOrderAudit(@Param('id') orderId: string) {
        const logs = await this.auditLogRepo.findByTarget('ORDER', orderId);
        return { success: true, orderId, logs, total: logs.length };
    }

    @Get('tasks/:id')
    @ApiOperation({ summary: 'Get audit trail for specific task' })
    async getTaskAudit(@Param('id') taskId: string) {
        const logs = await this.auditLogRepo.findByTarget('TASK', taskId);
        return { success: true, taskId, logs, total: logs.length };
    }
}
