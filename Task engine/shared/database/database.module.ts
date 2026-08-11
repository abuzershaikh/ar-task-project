import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { databaseConfig } from '../config/database.config';

// Entities
import { User } from './entities/user.entity';
import { Worker } from './entities/worker.entity';
import { WorkerScore } from './entities/worker-score.entity';
import { Order } from './entities/order.entity';
import { Task } from './entities/task.entity';
import { TaskSubmission } from './entities/submission.entity';
import { Earning } from './entities/earning.entity';
import { Withdrawal } from './entities/withdrawal.entity';
import { KycProfile } from './entities/kyc.entity';
import { PaymentMethod } from './entities/payment-method.entity';
import { Rating } from './entities/rating.entity';
import { File } from './entities/file.entity';
import { Notification } from './entities/notification.entity';
import { AuditLog } from './entities/audit-log.entity';
import { ServiceCatalog } from './entities/service-catalog.entity';
import { ServicePricing } from './entities/service-pricing.entity';
import { SystemSetting } from './entities/system-settings.entity';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { TaskGenerationJob } from './entities/task-generation-job.entity';
import { CampaignWorkerParticipation } from './entities/campaign-worker-participation.entity';
import { TaskAssignment } from './entities/task-assignment.entity';

// Repositories
import { UserRepository } from './repositories/user.repository';
import { WorkerRepository } from './repositories/worker.repository';
import { WorkerScoreRepository } from './repositories/worker-score.repository';
import { OrderRepository } from './repositories/order.repository';
import { TaskRepository } from './repositories/task.repository';
import { SubmissionRepository } from './repositories/submission.repository';
import { EarningRepository } from './repositories/earning.repository';
import { WithdrawalRepository } from './repositories/withdrawal.repository';
import { KycRepository } from './repositories/kyc.repository';
import { PaymentMethodRepository } from './repositories/payment-method.repository';
import { RatingRepository } from './repositories/rating.repository';
import { FileRepository } from './repositories/file.repository';
import { NotificationRepository } from './repositories/notification.repository';
import { AuditLogRepository } from './repositories/audit-log.repository';
import { ServiceCatalogRepository } from './repositories/service-catalog.repository';
import { ServicePricingRepository } from './repositories/service-pricing.repository';
import { SystemSettingsRepository } from './repositories/system-settings.repository';
import { PaymentTransactionRepository } from './repositories/payment-transaction.repository';
import { TaskGenerationJobRepository } from './repositories/task-generation-job.repository';
import { CampaignWorkerParticipationRepository } from './repositories/campaign-worker-participation.repository';
import { TaskAssignmentRepository } from './repositories/task-assignment.repository';

const entities = [
    User,
    Worker,
    WorkerScore,
    Order,
    Task,
    TaskSubmission,
    Earning,
    Withdrawal,
    KycProfile,
    PaymentMethod,
    Rating,
    File,
    Notification,
    AuditLog,
    ServiceCatalog,
    ServicePricing,
    SystemSetting,
    PaymentTransaction,
    TaskGenerationJob,
    CampaignWorkerParticipation,
    TaskAssignment,
];

const repositories = [
    UserRepository,
    WorkerRepository,
    WorkerScoreRepository,
    OrderRepository,
    TaskRepository,
    SubmissionRepository,
    EarningRepository,
    WithdrawalRepository,
    KycRepository,
    PaymentMethodRepository,
    RatingRepository,
    FileRepository,
    NotificationRepository,
    AuditLogRepository,
    ServiceCatalogRepository,
    ServicePricingRepository,
    SystemSettingsRepository,
    PaymentTransactionRepository,
    TaskGenerationJobRepository,
    CampaignWorkerParticipationRepository,
    TaskAssignmentRepository,
];

@Module({
    imports: [
        TypeOrmModule.forRoot(databaseConfig),
        TypeOrmModule.forFeature(entities),
    ],
    providers: [...repositories],
    exports: [...repositories, TypeOrmModule],
})
export class DatabaseModule { }
