type EnvValue = string | number | boolean | undefined;

const REQUIRED_KEYS = ['JWT_SECRET', 'JWT_REFRESH_SECRET', 'DB_DATABASE'];

export function validateEnvironment(config: Record<string, EnvValue>) {
    const missingKeys = REQUIRED_KEYS.filter((key) => !config[key]);

    if (missingKeys.length > 0) {
        throw new Error(`Missing required environment variables: ${missingKeys.join(', ')}`);
    }

    return {
        ...config,
        PORT: config.PORT ? Number(config.PORT) : 3000,
        DB_PORT: config.DB_PORT ? Number(config.DB_PORT) : 3306,
    };
}
