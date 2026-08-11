export interface Reward {
    taskId: string;
    baseReward: number;
    bonus: number;
    totalReward: number;
    currency: string;
    breakdown: {
        base: number;
        difficultyBonus: number;
        urgencyBonus: number;
        [key: string]: number;
    };
}

export interface RewardSnapshot {
    id: string;
    taskId: string;
    reward: Reward;
    snapshotAt: Date;
    ruleVersion: string;
}
