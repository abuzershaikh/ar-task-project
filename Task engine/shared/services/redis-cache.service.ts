import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisCacheService implements OnModuleInit, OnModuleDestroy {
    private readonly logger = new Logger(RedisCacheService.name);
    private client: Redis | null = null;
    private isConnected = false;

    constructor(private readonly configService: ConfigService) { }

    onModuleInit() {
        const host = this.configService.get<string>('REDIS_HOST', '127.0.0.1');
        const port = parseInt(this.configService.get<string>('REDIS_PORT', '6379'), 10);

        try {
            this.client = new Redis({
                host,
                port,
                maxRetriesPerRequest: 1,
                retryStrategy: (times) => Math.min(times * 100, 2000),
                enableOfflineQueue: false,
                lazyConnect: true,
            });

            this.client.connect().then(() => {
                this.isConnected = true;
                this.logger.log(`⚡ RedisCacheService connected to Redis at ${host}:${port}`);
            }).catch((err) => {
                this.logger.warn(`Redis connection failed (falling back to direct DB): ${err.message}`);
                this.isConnected = false;
            });

            this.client.on('error', (err) => {
                this.logger.warn(`Redis client error: ${err.message}`);
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                this.isConnected = true;
            });
        } catch (e: any) {
            this.logger.warn(`Could not initialize Redis client: ${e.message}`);
            this.isConnected = false;
        }
    }

    onModuleDestroy() {
        if (this.client) {
            this.client.disconnect();
        }
    }

    /**
     * Get item from Redis cache
     */
    async get<T>(key: string): Promise<T | null> {
        if (!this.isConnected || !this.client) return null;
        try {
            const data = await this.client.get(key);
            if (!data) return null;
            return JSON.parse(data) as T;
        } catch (err: any) {
            this.logger.warn(`Redis get error for key ${key}: ${err.message}`);
            return null;
        }
    }

    /**
     * Set item in Redis cache with optional TTL in seconds
     */
    async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
        if (!this.isConnected || !this.client) return;
        try {
            const str = JSON.stringify(value);
            if (ttlSeconds && ttlSeconds > 0) {
                await this.client.set(key, str, 'EX', ttlSeconds);
            } else {
                await this.client.set(key, str);
            }
        } catch (err: any) {
            this.logger.warn(`Redis set error for key ${key}: ${err.message}`);
        }
    }

    /**
     * Delete one or more keys from cache
     */
    async del(...keys: string[]): Promise<void> {
        if (!this.isConnected || !this.client || keys.length === 0) return;
        try {
            const validKeys = keys.filter(Boolean);
            if (validKeys.length > 0) {
                await this.client.del(...validKeys);
            }
        } catch (err: any) {
            this.logger.warn(`Redis del error: ${err.message}`);
        }
    }

    /**
     * Invalidate both available tasks and wallet balance cache for a given worker
     */
    async invalidateWorker(workerId: string): Promise<void> {
        if (!workerId) return;
        await this.del(
            `cache:worker:available:${workerId}`,
            `cache:worker:wallet:${workerId}`,
        );
    }
}
