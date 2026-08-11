export interface PayoutRequest {
    workerId: string;
    amount: number;
    paymentMethod: string;
    idempotencyKey?: string;
    metadata?: any;
}

export interface PayoutStatus {
    withdrawalId: string;
    status: 'pending' | 'processing' | 'completed' | 'failed';
    processedAt: Date;
    transactionId?: string;
    error?: string;
}

export interface PaymentMethod {
    id: string;
    workerId: string;
    type: 'bank' | 'upi';
    details: any;
    isDefault: boolean;
}
