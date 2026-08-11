import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { NotificationEngineService } from './notification.service';

@Module({
  imports: [DatabaseModule],
  providers: [NotificationEngineService],
  exports: [NotificationEngineService],
})
export class NotificationEngineModule {}
