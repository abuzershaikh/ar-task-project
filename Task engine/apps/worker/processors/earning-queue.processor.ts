import { Processor, Process } from '@nestjs/bull';
import { Job } from 'bull';
import { Injectable } from '@nestjs/common';
import { EarningEngineService } from '../../../earning-engine/earning.service';

/**
 * Earning queue processor
 * Worker earnings process karta hai
 */
@Processor('earning')
@Injectable()
export class EarningQueueProcessor {
    constructor(private readonly earningEngine: EarningEngineService) { }

    @Process('post-earning')
    async handlePostEarning(job: Job) {
        const { taskId, workerId } = job.data;

        console.log(`💰 Processing earning for task ${taskId}, worker ${workerId}`);

        try {
            // Calculate earning
            const earning = await this.earningEngine.calculateEarning(taskId, workerId);

            // Post to ledger
            await this.earningEngine.postEarning(earning);

            console.log(`✅ Earning posted: ${earning.amount}`);

            return { success: true, amount: earning.amount };
        } catch (error) {
            console.error('Failed to post earning:', error);
            throw error;
        }
    }

    @Process('reverse-earning')
    async handleReverseEarning(job: Job) {
        const { earningId } = job.data;

        console.log(`↩️ Reversing earning ${earningId}`);

        try {
            await this.earningEngine.reverseEarning(earningId);

            console.log(`✅ Earning reversed`);

            return { success: true };
        } catch (error) {
            console.error('Failed to reverse earning:', error);
            throw error;
        }
    }

    @Process('bulk-payout')
    async handleBulkPayout(job: Job) {
        console.log('💸 Processing bulk payout...');

        // TODO: Process multiple payouts in batch

        return { success: true };
    }
}
