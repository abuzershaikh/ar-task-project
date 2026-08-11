import {
    Controller,
    Get,
    Post,
    Param,
    Body,
    Query,
    NotFoundException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TaskRepository } from '../../../../shared/database/repositories/task.repository';
import { TaskEngineService } from '../../../../task-engine/task-engine.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Task Management')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/tasks')
export class AdminTaskManagementController {
    constructor(
        private readonly taskRepo: TaskRepository,
        private readonly taskEngine: TaskEngineService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all tasks across platform' })
    @ApiQuery({ name: 'status', required: false })
    async listTasks(@Query('status') status?: string) {
        if (status) {
            const tasks = await this.taskRepo.findByStatus(status);
            return { success: true, tasks, total: tasks.length };
        }

        const tasks = await this.taskRepo.findAvailableForAssignment();
        return { success: true, tasks, total: tasks.length };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get task detail' })
    async getTaskDetail(@Param('id') taskId: string) {
        const task = await this.taskRepo.findById(taskId);
        if (!task) {
            throw new NotFoundException('Task not found');
        }
        return { success: true, task };
    }

    @Post(':id/cancel')
    @ApiOperation({ summary: 'Force cancel a task' })
    async forceCancelTask(@Param('id') taskId: string, @Body() body: { reason?: string }) {
        await this.taskEngine.cancelTask({ taskId, reason: body.reason || 'Admin cancelled' });
        return { success: true, message: 'Task cancelled by admin' };
    }

    @Post(':id/reassign')
    @ApiOperation({ summary: 'Force reassign task to specific worker' })
    async forceReassignTask(
        @Param('id') taskId: string,
        @Body() body: { workerId: string },
    ) {
        await this.taskEngine.assignTask({ taskId, workerId: body.workerId });
        return { success: true, message: `Task reassigned to worker ${body.workerId}` };
    }
}
