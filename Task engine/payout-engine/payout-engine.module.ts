import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { NotificationEngineModule } from '../notification-engine/notification-engine.module';
import { EarningEngineModule } from '../earning-engine/earning-engine.module';
import { PayoutEngineService } from './payout.service';
import { WithdrawalService } from './services/withdrawal.service';
import { PayoutProcessor } from './processors/payout-processor';
import { PayoutConfigService } from './services/payout-config.service';

@Module({
    imports: [DatabaseModule, NotificationEngineModule, EarningEngineModule],
    providers: [PayoutEngineService, WithdrawalService, PayoutProcessor, PayoutConfigService],
    exports: [PayoutEngineService, PayoutConfigService],
})
export class PayoutEngineModule { }
