import { Injectable, Logger } from '@nestjs/common';
import { EligibilityResult } from './types/eligibility-result';

import { WorkerRepository } from '../shared/database/repositories/worker.repository';
import { TaskRepository } from '../shared/database/repositories/task.repository';
import { WorkerScoreRepository } from '../shared/database/repositories/worker-score.repository';
import { MIN_SCORE_THRESHOLD } from '../scoring-engine/types/worker-score';

/**
 * Eligibility Engine
 * Worker task ke liye eligible hai ya nahi check karta hai
 * 
 * NEW RULES:
 * 1. Worker must be active status
 * 2. Task must be active status
 * 3. lastActiveAt < 48 hours (HARD GATE — activity is NOT part of score)
 * 4. totalScore >= 40 (minimum score threshold)
 * 5. Worker must NOT be on task cooldown (rejection penalty)
 * 
 * IMPORTANT: Inactive worker ka score DELETE nahi hota.
 * Score preserved rahega, sirf task distribution stop hoga.
 */
@Injectable()
export class EligibilityEngineService {
    private readonly logger = new Logger(EligibilityEngineService.name);

    constructor(
        private readonly workerRepo: WorkerRepository,
        private readonly taskRepo: TaskRepository,
        private readonly scoreRepo: WorkerScoreRepository,
    ) { }

    async checkEligibility(
        workerId: string,
        taskId: string,
    ): Promise<EligibilityResult> {
        const reasons: string[] = [];
        let isEligible = true;

        if (!workerId || typeof workerId !== 'string') {
            return { isEligible: false, reasons: ['Invalid worker ID'], rules: {} };
        }

        if (!taskId || typeof taskId !== 'string') {
            return { isEligible: false, reasons: ['Invalid task ID'], rules: {} };
        }

        const [worker, task] = await Promise.all([
            this.workerRepo.findById(workerId),
            this.taskRepo.findById(taskId)
        ]);

        // Rule 1: Worker must exist and be active
        if (!worker) {
            isEligible = false;
            reasons.push('Worker not found');
        } else if (worker.status !== 'active') {
            isEligible = false;
            reasons.push('Worker is not active');
        }

        // Rule 2: Task must exist and be active
        if (!task) {
            isEligible = false;
            reasons.push('Task not found');
        } else if (task.status !== 'active') {
            isEligible = false;
            reasons.push('Task is not active');
        }

        // Rule 3: Activity check — 48h hard gate
        if (worker && !this.workerRepo.isActivityEligible(worker)) {
            isEligible = false;
            const activityStatus = this.workerRepo.getActivityStatus(worker);
            reasons.push(`Worker is ${activityStatus} (last active: ${worker.lastActiveAt || 'never'}). 48h inactivity = hard stop.`);
        }

        // Rule 4: Minimum score threshold check (score >= 40)
        if (worker && isEligible) {
            const scoreRecord = await this.scoreRepo.findByWorkerId(workerId);
            const totalScore = scoreRecord ? Number(scoreRecord.totalScore || 0) : 0;

            // New workers (no score record yet) get a pass — they have starter score 50
            if (scoreRecord && totalScore < MIN_SCORE_THRESHOLD) {
                isEligible = false;
                reasons.push(`Worker score ${totalScore} is below minimum threshold ${MIN_SCORE_THRESHOLD}. Score 0-39 = no automatic task distribution.`);
            }
        }

        // Rule 5: Cooldown check — rejection penalty
        if (worker && this.workerRepo.isOnCooldown(worker)) {
            isEligible = false;
            reasons.push(`Worker is on task cooldown until ${worker.taskCooldownUntil}. Repeated rejections trigger temporary cooldown.`);
        }

        return {
            isEligible,
            reasons,
            rules: {
                workerActive: worker?.status === 'active',
                taskActive: task?.status === 'active',
                activityEligible: worker ? this.workerRepo.isActivityEligible(worker) : false,
                activityStatus: worker ? this.workerRepo.getActivityStatus(worker) : 'INACTIVE',
                scoreAboveThreshold: true, // updated below if score check failed
                onCooldown: worker ? this.workerRepo.isOnCooldown(worker) : false,
            },
        };
    }

    async batchCheckEligibility(
        workerIds: string[],
        taskId: string,
    ): Promise<Map<string, EligibilityResult>> {
        const results = new Map<string, EligibilityResult>();

        if (!workerIds || workerIds.length === 0) return results;

        // Fetch task once for batch
        const task = await this.taskRepo.findById(taskId);
        if (!task || task.status !== 'active') {
             for (const id of workerIds) {
                 results.set(id, { isEligible: false, reasons: ['Task not active or found'], rules: {} });
             }
             return results;
        }

        // Fetch workers in bulk
        const workers = await this.workerRepo.findByIds(workerIds);

        // Fetch scores in bulk for minimum threshold check
        const scores = await this.scoreRepo.findByWorkerIds(workerIds);
        const scoreMap = new Map(scores.map(s => [s.workerId, Number(s.totalScore || 0)]));

        for (const workerId of workerIds) {
            const worker = workers.find(w => w.id === workerId);
            const reasons: string[] = [];
            let isEligible = true;

            // Rule 1: Worker must be active
            if (!worker || worker.status !== 'active') {
                isEligible = false;
                reasons.push('Worker not found or not active');
            }

            // Rule 3: Activity check — 48h hard gate
            if (worker && !this.workerRepo.isActivityEligible(worker)) {
                isEligible = false;
                const activityStatus = this.workerRepo.getActivityStatus(worker);
                reasons.push(`Worker ${activityStatus} — 48h inactivity hard stop`);
            }

            // Rule 4: Minimum score threshold (>= 40)
            if (worker && isEligible) {
                const workerScore = scoreMap.get(workerId);
                // If no score record exists, allow (new worker with starter score 50)
                if (workerScore !== undefined && workerScore < MIN_SCORE_THRESHOLD) {
                    isEligible = false;
                    reasons.push(`Score ${workerScore} below minimum ${MIN_SCORE_THRESHOLD}`);
                }
            }

            // Rule 5: Cooldown check
            if (worker && this.workerRepo.isOnCooldown(worker)) {
                isEligible = false;
                reasons.push(`On task cooldown until ${worker.taskCooldownUntil}`);
            }

            const activityStatus = worker ? this.workerRepo.getActivityStatus(worker) : 'INACTIVE';

            results.set(workerId, {
                isEligible,
                reasons,
                rules: {
                    workerActive: worker?.status === 'active',
                    taskActive: true,
                    activityEligible: worker ? this.workerRepo.isActivityEligible(worker) : false,
                    activityStatus,
                    onCooldown: worker ? this.workerRepo.isOnCooldown(worker) : false,
                }
            });
        }

        return results;
    }
}
