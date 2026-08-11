import { Injectable, Logger } from '@nestjs/common';
import { TaskCommandService } from './handlers/task-command.service';
import { TaskQueryService } from './queries/task-query.service';
import { CreateTaskCommand } from './commands/create-task.command';
import { AssignTaskCommand } from './commands/assign-task.command';
import { AcceptTaskCommand } from './commands/accept-task.command';
import { StartTaskCommand } from './commands/start-task.command';
import { SubmitTaskCommand } from './commands/submit-task.command';
import { ApproveTaskCommand } from './commands/approve-task.command';
import { RejectTaskCommand } from './commands/reject-task.command';
import { CancelTaskCommand } from './commands/cancel-task.command';

@Injectable()
export class TaskEngineService {
    private readonly logger = new Logger(TaskEngineService.name);

    constructor(
        private readonly commandService: TaskCommandService,
        private readonly queryService: TaskQueryService,
    ) { }

    async createTask(command: CreateTaskCommand) {
        this.logger.log(`Creating task for order: ${command.orderId}`);
        return this.commandService.createTask(command);
    }

    async assignTask(command: AssignTaskCommand) {
        this.logger.log(`Assigning task ${command.taskId} to worker ${command.workerId}`);
        return this.commandService.assignTask(command);
    }

    async acceptTask(command: AcceptTaskCommand) {
        this.logger.log(`Worker ${command.workerId} accepting task ${command.taskId}`);
        return this.commandService.acceptTask(command);
    }

    async startTask(command: StartTaskCommand) {
        this.logger.log(`Starting task ${command.taskId}`);
        return this.commandService.startTask(command);
    }

    async submitTask(command: SubmitTaskCommand) {
        this.logger.log(`Submitting task ${command.taskId}`);
        return this.commandService.submitTask(command);
    }

    async approveTask(command: ApproveTaskCommand) {
        this.logger.log(`Approving task ${command.taskId}`);
        return this.commandService.approveTask(command);
    }

    async rejectTask(command: RejectTaskCommand) {
        this.logger.log(`Rejecting task ${command.taskId}`);
        return this.commandService.rejectTask(command);
    }

    async cancelTask(command: CancelTaskCommand) {
        this.logger.log(`Canceling task ${command.taskId}`);
        return this.commandService.cancelTask(command);
    }

    async getTaskById(taskId: string) {
        return this.queryService.getTaskById(taskId);
    }

    async getAvailableTasks(workerId: string) {
        return this.queryService.getAvailableTasks(workerId);
    }

    async getWorkerTasks(workerId: string, status?: string) {
        return this.queryService.getWorkerTasks(workerId, status);
    }
}
