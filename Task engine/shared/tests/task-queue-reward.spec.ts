import { TaskQueueProcessor } from '../../apps/worker/processors/task-queue.processor';

describe('TaskQueueProcessor reward safety', () => {
    const createProcessor = (order: any) => {
        const createdRewards: number[] = [];
        const taskEngine = {
            createTask: jest.fn(async (input) => {
                createdRewards.push(input.rewardAmount);
                return { id: `task-${createdRewards.length}` };
            }),
        };
        const rewardEngine = { createSnapshot: jest.fn(async () => undefined) };
        const jobRepo = {
            findByOrderId: jest.fn(async () => null),
            updateProgress: jest.fn(async () => undefined),
        };
        const orderRepo = { findById: jest.fn(async () => order) };
        const matchingQueue = { add: jest.fn(async () => undefined) };
        const processor = new TaskQueueProcessor(
            taskEngine as any,
            rewardEngine as any,
            jobRepo as any,
            orderRepo as any,
            {} as any,
            matchingQueue as any,
        );

        return { processor, createdRewards, taskEngine };
    };

    it('uses the order worker reward snapshot when a queue job has no reward', async () => {
        const { processor, createdRewards } = createProcessor({ workerRewardSnapshot: 1.50 });

        await processor.handleCreateTasks({
            data: { orderId: 'order-1', count: 1, taskType: 'TEST', requirements: {} },
        } as any);

        expect(createdRewards).toEqual([1.50]);
    });

    it('refuses to create a task when neither the job nor the order has a positive reward', async () => {
        const { processor, taskEngine } = createProcessor(null);

        await expect(processor.handleCreateTasks({
            data: { orderId: 'missing-order', count: 1, taskType: 'TEST', requirements: {} },
        } as any)).rejects.toThrow('positive worker reward snapshot is required');

        expect(taskEngine.createTask).not.toHaveBeenCalled();
    });
});
