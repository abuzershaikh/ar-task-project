import { Injectable, NotFoundException } from '@nestjs/common';
import { RatingRepository } from '../database/repositories/rating.repository';
import { WorkerRepository } from '../database/repositories/worker.repository';
import { TaskRepository } from '../database/repositories/task.repository';
import { ScoringEngineService } from '../../scoring-engine/scoring.service';

@Injectable()
export class RatingEngineService {
    constructor(
        private readonly ratingRepo: RatingRepository,
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
        private readonly scoringEngine: ScoringEngineService,
    ) { }

    async submitTaskRating(params: {
        buyerId: string;
        taskId: string;
        score: number;
        feedback?: string;
    }) {
        const task = await this.taskRepo.findById(params.taskId);
        if (!task || !task.assignedTo) {
            throw new NotFoundException('Task or assigned worker not found');
        }

        const workerId = task.assignedTo;

        const rating = await this.ratingRepo.create({
            buyerId: params.buyerId,
            workerId,
            taskId: params.taskId,
            rating: params.score,
            feedback: params.feedback,
        });

        // Recalculate average rating for worker
        const summary = await this.ratingRepo.getWorkerRatingSummary(workerId);
        await this.workerRepo.update(workerId, {
            averageRating: summary.average,
        });

        // Trigger Scoring Engine recalculation so score updates in Matching Brain
        await this.scoringEngine.calculateWorkerScore(workerId);

        return {
            rating,
            workerAverageRating: summary.average,
            totalRatingsCount: summary.count,
        };
    }
}
