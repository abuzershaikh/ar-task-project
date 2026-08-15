import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export const databaseConfig: TypeOrmModuleOptions = {
    type: 'mysql',
    url: process.env.DATABASE_URL || 'mysql://taskapp:taskapp_password@localhost:3306/task_platform',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 3306,
    username: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD || 'taskapp_password',
    database: process.env.DB_DATABASE || 'task_platform',
    autoLoadEntities: true,
    migrations: [__dirname + '/../database/migrations/**/*{.ts,.js}'],
    synchronize: process.env.NODE_ENV === 'development',
    logging: false,
    charset: 'utf8mb4',
    timezone: '+00:00',
    poolSize: 10,
};
