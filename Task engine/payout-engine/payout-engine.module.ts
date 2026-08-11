import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { PayoutEngineService } from './payout.service';
import { WithdrawalService } from './services/withdrawal.service';
import { PayoutProcessor } from './processors/payout-processor';
import { PayoutConfigService } from './services/payout-config.service';

@Module({
    imports: [DatabaseModule],
    providers: [PayoutEngineService, WithdrawalService, PayoutProcessor, PayoutConfigService],
    exports: [PayoutEngineService, PayoutConfigService],
})
export class PayoutEngineModule { }
