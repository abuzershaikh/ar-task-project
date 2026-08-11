import { NestFactory } from '@nestjs/core';
import { WorkerModule } from './worker.module';

/**
 * Background Worker Process
 * Queue processing aur async tasks handle karta hai
 */
async function bootstrap() {
    const app = await NestFactory.create(WorkerModule);

    await app.init();

    console.log('🔧 Worker process started');
    console.log('📥 Listening to queues...');
}

bootstrap();
