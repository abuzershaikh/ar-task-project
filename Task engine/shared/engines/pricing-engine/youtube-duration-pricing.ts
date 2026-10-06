/**
 * Keeps the buyer price, worker payout and platform margin in balance when a
 * YouTube Combo order requires more than the included five minutes.
 *
 * Values persisted to the database use two decimal places, so every returned
 * value is rounded as a currency amount before it is used in an order.
 */
export interface YouTubeDurationPricingInput {
    baseBuyerUnitPrice: number;
    baseWorkerReward: number;
    marginType: string;
    watchTimeSeconds: number;
    extraPricePerMinute: number;
}

export interface YouTubeDurationPricingResult {
    extraMinutes: number;
    extraPerUnit: number;
    buyerUnitPrice: number;
    workerReward: number;
    platformMargin: number;
}

const INCLUDED_WATCH_SECONDS = 5 * 60;

export function roundCurrency(value: number): number {
    if (!Number.isFinite(value)) {
        throw new Error('Currency amount must be a finite number');
    }
    return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function calculateYouTubeDurationPricing(
    input: YouTubeDurationPricingInput,
): YouTubeDurationPricingResult {
    const baseBuyerUnitPrice = Number(input.baseBuyerUnitPrice);
    const baseWorkerReward = Number(input.baseWorkerReward);
    const extraPricePerMinute = Number(input.extraPricePerMinute);
    const watchTimeSeconds = Number(input.watchTimeSeconds);
    const marginType = String(input.marginType || '').toUpperCase();

    if (!Number.isFinite(baseBuyerUnitPrice) || baseBuyerUnitPrice <= 0) {
        throw new Error('Base buyer unit price must be greater than zero');
    }
    if (!Number.isFinite(baseWorkerReward) || baseWorkerReward <= 0 || baseWorkerReward > baseBuyerUnitPrice) {
        throw new Error('Base worker reward must be greater than zero and cannot exceed buyer price');
    }
    if (!Number.isFinite(extraPricePerMinute) || extraPricePerMinute < 0) {
        throw new Error('Extra price per minute cannot be negative or invalid');
    }
    if (!Number.isFinite(watchTimeSeconds) || watchTimeSeconds < 0) {
        throw new Error('Watch time must be a non-negative number');
    }
    if (marginType !== 'PERCENTAGE' && marginType !== 'FIXED') {
        throw new Error(`Unsupported margin type '${input.marginType}'`);
    }

    const extraMinutes = Math.max(0, Math.ceil((watchTimeSeconds - INCLUDED_WATCH_SECONDS) / 60));
    const extraPerUnit = roundCurrency(extraMinutes * extraPricePerMinute);
    const buyerUnitPrice = roundCurrency(baseBuyerUnitPrice + extraPerUnit);

    // Percentage pricing retains the exact configured worker share. For a
    // fixed platform fee, the fee remains fixed and the worker receives the
    // full extra-duration amount.
    const workerExtra = marginType === 'PERCENTAGE'
        ? extraPerUnit * (baseWorkerReward / baseBuyerUnitPrice)
        : extraPerUnit;
    const workerReward = roundCurrency(baseWorkerReward + workerExtra);
    const platformMargin = roundCurrency(buyerUnitPrice - workerReward);

    if (workerReward <= 0 || workerReward > buyerUnitPrice || platformMargin < 0) {
        throw new Error('Duration pricing produced an invalid worker payout');
    }

    return {
        extraMinutes,
        extraPerUnit,
        buyerUnitPrice,
        workerReward,
        platformMargin,
    };
}
