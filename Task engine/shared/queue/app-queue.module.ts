import { Module, Global } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { ConfigModule, ConfigService } from '@nestjs/config';

@Global()
@Module({
  imports: [
    BullModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        redis: {
          host: configService.get<string>('REDIS_HOST', 'localhost'),
          port: parseInt(configService.get<string>('REDIS_PORT', '6379'), 10),
        },
      }),
      inject: [ConfigService],
    }),
    BullModule.registerQueue(
      { name: 'task' },
      { name: 'matching' },
      { name: 'allocation' },
      { name: 'earning' },
    ),
  ],
  exports: [BullModule],
})
export class AppQueueModule {}
