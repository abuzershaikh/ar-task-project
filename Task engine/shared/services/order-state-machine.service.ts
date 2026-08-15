import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { OrderRepository } from '../database/repositories/order.repository';
import { TaskGenerationJobRepository } from '../database/repositories/task-generation-job.repository';
import { TaskGenerationJobStatus } from '../database/entities/task-generation-job.entity';
import { Order } from '../database/entities/order.entity';

export enum OrderStatus {
    DRAFT = 'DRAFT',
    PAYMENT_PENDING = 'PAYMENT_PENDING',
    ACTIVE = 'ACTIVE',
    PAUSED = 'PAUSED',
    COMPLETED = 'COMPLETED',
    CANCELLED = 'CANCELLED',
}

@Injectable()
export class OrderStateMachineService {
    private readonly logger = new Logger(OrderStateMachineService.name);

    constructor(
        private readonly dataSource: DataSource,
        private readonly orderRepo: OrderRepository,
        private readonly jobRepo: TaskGenerationJobRepository,
        private readonly eventEmitter: EventEmitter2,
    ) { }

    async transitionToActive(orderId: string, paymentTransactionId?: string): Promise<Order> {
        return this.dataSource.transaction(async (manager) => {
            const order = await manager.findOne(Order, {
                where: { id: orderId },
                lock: { mode: 'pessimistic_write' },
            });
            
            if (!order) {
                throw new NotFoundException(`Order with ID '${orderId}' not found`);
            }

            // Protection Pillar 1: Guard against duplicate activation
            if (order.status === OrderStatus.ACTIVE || order.status === 'ACTIVE') {
                this.logger.warn(`Order '${orderId}' is ALREADY ACTIVE. Ignoring duplicate activation attempt.`);
                return order;
            }

            const validPrevStatuses = [OrderStatus.DRAFT, OrderStatus.PAYMENT_PENDING, 'draft', 'DRAFT', 'PAYMENT_PENDING'];
            if (!validPrevStatuses.includes(order.status)) {
                this.logger.warn(`Order '${orderId}' cannot transition to ACTIVE from current status '${order.status}'`);
                return order;
            }

            order.status = OrderStatus.ACTIVE;
            const updated = await manager.save(order);

            const workerRewardSnapshot = Number(order.workerRewardSnapshot || order.rewardPerTask);

            // Protection Pillar 3: Durable Outbox TaskGenerationJob record
            let job = await this.jobRepo.findByOrderId(orderId);
            if (!job) {
                job = await this.jobRepo.create({
                    orderId,
                    totalTasksRequired: order.totalTasksRequired,
                    generatedTasksCount: 0,
                    workerRewardSnapshot,
                    status: TaskGenerationJobStatus.PENDING,
                });
            }

            this.logger.log(`Order '${orderId}' transitioned to ACTIVE. Job '${job.id}' created. Dispatching 'order.activated' event.`);

            // Protection Pillar 5: Lock financial snapshot in event payload (zero recalculation)
            this.eventEmitter.emit('order.activated', {
                orderId: order.id,
                jobId: job.id,
                buyerId: order.buyerId,
                serviceCode: order.serviceCode || order.taskType,
                totalTasksRequired: order.totalTasksRequired,
                workerRewardSnapshot,
                paymentTransactionId,
                activatedAt: new Date(),
            });

            return updated;
        });
    }

    async transitionToPaused(orderId: string): Promise<Order> {
        return this.dataSource.transaction(async (manager) => {
            const order = await manager.findOne(Order, {
                where: { id: orderId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!order) {
                throw new NotFoundException(`Order with ID '${orderId}' not found`);
            }

            if (order.status !== OrderStatus.ACTIVE && order.status !== 'ACTIVE') {
                throw new BadRequestException(`Cannot pause order with current status '${order.status}'`);
            }

            order.status = OrderStatus.PAUSED;
            const updated = await manager.save(order);
            this.eventEmitter.emit('order.paused', { orderId });
            return updated;
        });
    }

    async transitionToResume(orderId: string): Promise<Order> {
        return this.dataSource.transaction(async (manager) => {
            const order = await manager.findOne(Order, {
                where: { id: orderId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!order) {
                throw new NotFoundException(`Order with ID '${orderId}' not found`);
            }

            if (order.status !== OrderStatus.PAUSED) {
                throw new BadRequestException(`Cannot resume order with current status '${order.status}'`);
            }

            order.status = OrderStatus.ACTIVE;
            const updated = await manager.save(order);
            this.eventEmitter.emit('order.resumed', { orderId });
            return updated;
        });
    }

    async transitionToCancelled(orderId: string, reason?: string): Promise<Order> {
        return this.dataSource.transaction(async (manager) => {
            const order = await manager.findOne(Order, {
                where: { id: orderId },
                lock: { mode: 'pessimistic_write' },
            });
            if (!order) {
                throw new NotFoundException(`Order with ID '${orderId}' not found`);
            }

            order.status = OrderStatus.CANCELLED;
            const updated = await manager.save(order);
            this.eventEmitter.emit('order.cancelled', { orderId, reason });
            return updated;
        });
    }
}
