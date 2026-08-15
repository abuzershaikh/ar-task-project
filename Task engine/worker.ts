import { NestFactory } from '@nestjs/core';
import { WorkerModule } from './apps/worker/worker.module';

/**
 * Dedicated Background Worker Process Entrypoint
 * Queue processing and async tasks execution
 */
async function bootstrap() {
    const app = await NestFactory.create(WorkerModule);
    app.enableShutdownHooks();
    await app.init();
    console.log('🔧 Dedicated Background Worker Process Started');
    console.log('📥 Listening to Bull Redis Queues...');
}

bootstrap();
