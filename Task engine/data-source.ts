import { DataSource } from "typeorm";
import { databaseConfig } from "./shared/config/database.config";
import { User } from "./shared/database/entities/user.entity";
import { Worker } from "./shared/database/entities/worker.entity";
import { WorkerScore } from "./shared/database/entities/worker-score.entity";
import { Order } from "./shared/database/entities/order.entity";
import { Task } from "./shared/database/entities/task.entity";
import { TaskSubmission } from "./shared/database/entities/submission.entity";
import { Earning } from "./shared/database/entities/earning.entity";
import { Withdrawal } from "./shared/database/entities/withdrawal.entity";
import { KycProfile } from "./shared/database/entities/kyc.entity";
import { PaymentMethod } from "./shared/database/entities/payment-method.entity";
import { Rating } from "./shared/database/entities/rating.entity";
import { File } from "./shared/database/entities/file.entity";
import { Notification } from "./shared/database/entities/notification.entity";
import { AuditLog } from "./shared/database/entities/audit-log.entity";
import { ServiceCatalog } from "./shared/database/entities/service-catalog.entity";
import { ServicePricing } from "./shared/database/entities/service-pricing.entity";
import { SystemSetting } from "./shared/database/entities/system-settings.entity";
import { PaymentTransaction } from "./shared/database/entities/payment-transaction.entity";
import { TaskGenerationJob } from "./shared/database/entities/task-generation-job.entity";
import { CampaignWorkerParticipation } from "./shared/database/entities/campaign-worker-participation.entity";
import { TaskAssignment } from "./shared/database/entities/task-assignment.entity";
import { Wallet } from "./shared/database/entities/wallet.entity";
import { WalletTransaction } from "./shared/database/entities/wallet-transaction.entity";

export const AppDataSource = new DataSource({
    type: "mysql",
    url: (databaseConfig as any).url as string,
    host: (databaseConfig as any).host as string,
    port: (databaseConfig as any).port as number,
    username: (databaseConfig as any).username as string,
    password: (databaseConfig as any).password as string,
    database: (databaseConfig as any).database as string,
    synchronize: false,
    logging: false,
    entities: [
        User, Worker, WorkerScore, Order, Task, TaskSubmission, Earning, Withdrawal,
        KycProfile, PaymentMethod, Rating, File, Notification, AuditLog, ServiceCatalog,
        ServicePricing, SystemSetting, PaymentTransaction, TaskGenerationJob,
        CampaignWorkerParticipation, TaskAssignment, Wallet, WalletTransaction
    ],
    migrations: ["./shared/database/migrations/*.ts"],
});
