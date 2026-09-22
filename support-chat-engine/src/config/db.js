const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'taskapp',
  password: process.env.DB_PASSWORD || 'taskapp_password',
  database: process.env.DB_NAME || 'task_platform',
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000,
});

async function initTables() {
  const connection = await pool.getConnection();
  try {
    console.log('[DB] Ensuring support chat tables exist...');

    // 1. support_conversations
    await connection.query(`
      CREATE TABLE IF NOT EXISTS support_conversations (
        id VARCHAR(36) PRIMARY KEY,
        worker_id VARCHAR(255) NOT NULL UNIQUE,
        worker_name VARCHAR(255) NULL,
        worker_phone VARCHAR(50) NULL,
        worker_email VARCHAR(255) NULL,
        last_message_text TEXT NULL,
        last_message_type VARCHAR(20) DEFAULT 'TEXT',
        last_message_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        unread_admin_count INT NOT NULL DEFAULT 0,
        unread_worker_count INT NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_conv_worker (worker_id),
        INDEX idx_conv_last_msg (last_message_at DESC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    // 2. support_messages
    await connection.query(`
      CREATE TABLE IF NOT EXISTS support_messages (
        id VARCHAR(36) PRIMARY KEY,
        conversation_id VARCHAR(36) NOT NULL,
        worker_id VARCHAR(255) NOT NULL,
        sender_type ENUM('WORKER', 'ADMIN') NOT NULL,
        message_type ENUM('TEXT', 'IMAGE', 'AUDIO', 'YOUTUBE') NOT NULL DEFAULT 'TEXT',
        content TEXT NOT NULL,
        media_url TEXT NULL,
        youtube_id VARCHAR(100) NULL,
        duration_seconds INT NOT NULL DEFAULT 0,
        is_read TINYINT(1) NOT NULL DEFAULT 0,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_msg_conv (conversation_id),
        INDEX idx_msg_worker (worker_id),
        INDEX idx_msg_created (created_at ASC)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    console.log('[DB] Support chat tables verified successfully.');
  } catch (err) {
    console.error('[DB] Error initializing tables:', err);
  } finally {
    connection.release();
  }
}

module.exports = {
  pool,
  initTables,
};
