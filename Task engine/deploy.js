const { Client } = require('ssh2');

const conn = new Client();

const findAndDeployCmd = `
#!/bin/bash
PROJECT_DIR="/var/www/task-engine/Task engine"

if [ ! -d "$PROJECT_DIR" ]; then
    PROJECT_DIR="/var/www/task-engine"
fi

if [ ! -f "$PROJECT_DIR/package.json" ]; then
    echo "Could not find package.json in $PROJECT_DIR"
    exit 1
fi

echo "Found project at: $PROJECT_DIR"
cd "$PROJECT_DIR"

GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

echo "Resetting code to origin/main..."
git fetch origin
git reset --hard origin/main
git pull origin main

cd "$PROJECT_DIR"

echo "Installing NPM dependencies..."
npm install

echo "Building the project..."
npm run build

echo "Setting up data-source.ts..."
cat << 'EOF' > data-source.ts
import { DataSource } from 'typeorm';
require('dotenv').config();
export const AppDataSource = new DataSource({
    type: 'mysql',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    username: process.env.DB_USERNAME || 'taskapp',
    password: process.env.DB_PASSWORD || 'taskapp_password',
    database: process.env.DB_DATABASE || 'task_platform',
    migrations: [__dirname + '/dist/shared/database/migrations/*{.ts,.js}'],
});
EOF

echo "Running migrations..."
npx ts-node -O '{"module":"commonjs"}' ./node_modules/typeorm/cli.js migration:run -d data-source.ts || npx typeorm migration:run -d data-source.ts

echo "Restarting PM2..."
pm2 restart all
`;

conn.on('ready', () => {
    console.log('Client :: ready');
    conn.exec(findAndDeployCmd, (err, stream) => {
        if (err) throw err;
        stream.on('close', (code, signal) => {
            console.log('Stream :: close :: code: ' + code + ', signal: ' + signal);
            conn.end();
        }).on('data', (data) => {
            console.log('STDOUT: ' + data);
        }).stderr.on('data', (data) => {
            console.log('STDERR: ' + data);
        });
    });
}).connect({
    host: '95.179.178.6',
    port: 22,
    username: 'root',
    password: 'i_G72#y}(6gACDDU'
});
