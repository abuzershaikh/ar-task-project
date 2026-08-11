import { Injectable } from '@nestjs/common';

@Injectable()
export class PayoutConfigService {
    private globalMinWithdrawalLimit = 100.0;

    getGlobalMinWithdrawalLimit(): number {
        return this.globalMinWithdrawalLimit;
    }

    setGlobalMinWithdrawalLimit(limit: number): void {
        if (limit >= 0) {
            this.globalMinWithdrawalLimit = limit;
        }
    }
}
