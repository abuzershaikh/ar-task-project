import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { EligibilityEngineService } from './eligibility.service';

@Module({
    imports: [DatabaseModule],
    providers: [EligibilityEngineService],
    exports: [EligibilityEngineService],
})
export class EligibilityEngineModule { }
