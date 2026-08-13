import { Module, Global, forwardRef } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { AuditLogService } from './audit-log.service';
import { NotificationService } from './notification.service';
import { FileStorageService } from './file-storage.service';
import { PricingEngineService } from './pricing-engine.service';
import { RatingEngineService } from './rating-engine.service';

// Pricing Engine Calculators & Services
import { MarginCalculator } from '../engines/pricing-engine/margin-calculator';
import { RewardCalculator } from '../engines/pricing-engine/reward-calculator';
import { PriceCalculator } from '../engines/pricing-engine/price-calculator';
import { PriceSnapshotService } from '../engines/pricing-engine/price-snapshot.service';
import { PricingVersionService } from '../engines/pricing-engine/pricing-version.service';
import { PricingEngine } from '../engines/pricing-engine/pricing.engine';

// Service Catalog Services
import { ServiceCatalogService } from '../modules/service-catalog/services/service-catalog.service';
import { ServicePricingService } from '../modules/service-catalog/services/service-pricing.service';
import { ServiceVersionService } from '../modules/service-catalog/services/service-version.service';

// Order State Machine & Event Listeners
import { OrderStateMachineService } from './order-state-machine.service';
import { OrderActivatedListener } from './order-activated.listener';
import { TaskEngineModule } from '../../task-engine/task-engine.module';
import { MatchingEngineModule } from '../../matching-engine/matching-engine.module';

// Reallocation Engine Services
import { TaskReleaseService } from '../engines/reallocation-engine/services/task-release.service';
import { ReassignmentService } from '../engines/reallocation-engine/services/reassignment.service';
import { DeadlineMonitorService } from '../engines/reallocation-engine/services/deadline-monitor.service';
import { ReallocationEngine } from '../engines/reallocation-engine/reallocation.engine';

const providers = [
    AuditLogService,
    NotificationService,
    FileStorageService,
    PricingEngineService,
    RatingEngineService,
    MarginCalculator,
    RewardCalculator,
    PriceCalculator,
    PriceSnapshotService,
    PricingVersionService,
    PricingEngine,
    ServiceCatalogService,
    ServicePricingService,
    ServiceVersionService,
    OrderStateMachineService,
    OrderActivatedListener,
    TaskReleaseService,
    ReassignmentService,
    DeadlineMonitorService,
    ReallocationEngine,
];

@Global()
@Module({
    imports: [DatabaseModule, forwardRef(() => TaskEngineModule), forwardRef(() => MatchingEngineModule)],
    providers,
    exports: providers,
})
export class ServicesModule { }
