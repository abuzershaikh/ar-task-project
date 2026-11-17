const fs = require('fs');
const path = require('path');

const cmdPath = path.resolve(__dirname, '../Task engine/task-engine/handlers/task-command.service.ts');
let cmdContent = fs.readFileSync(cmdPath, 'utf8');

// 1. In assignTask
const oldAssignBlock = `                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ASSIGNED,
                    assignedAt: new Date(),
                });
                await manager.save(assignment);

                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.assignedAt = new Date();
                task.status = TaskStatus.ASSIGNED;`;

const newAssignBlock = `                const maxAttemptRow = await manager.query(
                    'SELECT COALESCE(MAX(attempt_number), 0) AS max_attempt FROM task_assignments WHERE task_id = ?',
                    [task.id],
                );
                const maxAttempt = Number(maxAttemptRow?.[0]?.max_attempt || 0);
                const nextAttemptNumber = Math.max(maxAttempt, task.attemptCount || 0) + 1;

                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: nextAttemptNumber,
                    status: TaskAssignmentStatus.ASSIGNED,
                    assignedAt: new Date(),
                });
                await manager.save(assignment);

                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.assignedAt = new Date();
                task.attemptCount = nextAttemptNumber;
                task.status = TaskStatus.ASSIGNED;`;

// 2. In acceptTask
const oldAcceptBlock = `                const attempts = await manager.find(TaskAssignment, { where: { taskId: task.id } });
                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: attempts.length + 1,
                    status: TaskAssignmentStatus.ACCEPTED,
                    assignedAt: new Date(),
                    acceptedAt: new Date(),
                });
                await manager.save(assignment);`;

const newAcceptBlock = `                const maxAttemptRow = await manager.query(
                    'SELECT COALESCE(MAX(attempt_number), 0) AS max_attempt FROM task_assignments WHERE task_id = ?',
                    [task.id],
                );
                const maxAttempt = Number(maxAttemptRow?.[0]?.max_attempt || 0);
                const nextAttemptNumber = Math.max(maxAttempt, task.attemptCount || 0) + 1;

                const assignment = manager.create(TaskAssignment, {
                    taskId: task.id,
                    campaignId,
                    orderId,
                    orderUnitId,
                    workerId: primaryWorkerKey,
                    attemptNumber: nextAttemptNumber,
                    status: TaskAssignmentStatus.ACCEPTED,
                    assignedAt: new Date(),
                    acceptedAt: new Date(),
                });
                await manager.save(assignment);`;

// Also update task.attemptCount in acceptTask
const oldAcceptTaskSave = `                task.status = TaskStatus.ACCEPTED;
                task.acceptedAt = now;
                task.assignedAt = now;
                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.deadline = deadline;
                const saved = await manager.save(task);`;

const newAcceptTaskSave = `                task.status = TaskStatus.ACCEPTED;
                task.acceptedAt = now;
                task.assignedAt = now;
                task.assignedTo = primaryWorkerKey;
                task.orderUnitId = orderUnitId;
                task.attemptCount = nextAttemptNumber;
                task.deadline = deadline;
                const saved = await manager.save(task);`;

// Check line endings and replace normalized
function replaceBlock(str, oldB, newB) {
  const normStr = str.replace(/\r\n/g, '\n');
  const normOld = oldB.replace(/\r\n/g, '\n');
  const normNew = newB.replace(/\r\n/g, '\n');
  if (!normStr.includes(normOld)) {
    throw new Error('Block not found: ' + normOld.substring(0, 50));
  }
  const replaced = normStr.replace(normOld, normNew);
  return str.includes('\r\n') ? replaced.replace(/\n/g, '\r\n') : replaced;
}

cmdContent = replaceBlock(cmdContent, oldAssignBlock, newAssignBlock);
cmdContent = replaceBlock(cmdContent, oldAcceptBlock, newAcceptBlock);
cmdContent = replaceBlock(cmdContent, oldAcceptTaskSave, newAcceptTaskSave);

fs.writeFileSync(cmdPath, cmdContent, 'utf8');
console.log('Successfully updated task-command.service.ts');

// 3. Update task-assignment.repository.ts
const repoPath = path.resolve(__dirname, '../Task engine/shared/database/repositories/task-assignment.repository.ts');
let repoContent = fs.readFileSync(repoPath, 'utf8');

const oldRepoBlock = `    async createAssignment(data: Partial<TaskAssignment>): Promise<TaskAssignment> {
        const attempts = await this.findByTaskId(data.taskId!);
        const attemptNumber = attempts.length + 1;

        const assignment = this.repository.create({
            ...data,
            attemptNumber,
            status: TaskAssignmentStatus.ASSIGNED,
            assignedAt: new Date(),
        });

        return this.repository.save(assignment);
    }`;

const newRepoBlock = `    async createAssignment(data: Partial<TaskAssignment>): Promise<TaskAssignment> {
        const maxRow = await this.repository.query(
            'SELECT COALESCE(MAX(attempt_number), 0) AS max_attempt FROM task_assignments WHERE task_id = ?',
            [data.taskId],
        );
        const maxAttempt = Number(maxRow?.[0]?.max_attempt || 0);
        const attemptNumber = maxAttempt + 1;

        const assignment = this.repository.create({
            ...data,
            attemptNumber,
            status: TaskAssignmentStatus.ASSIGNED,
            assignedAt: new Date(),
        });

        return this.repository.save(assignment);
    }`;

repoContent = replaceBlock(repoContent, oldRepoBlock, newRepoBlock);
fs.writeFileSync(repoPath, repoContent, 'utf8');
console.log('Successfully updated task-assignment.repository.ts');

