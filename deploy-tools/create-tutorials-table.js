const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connected to VPS. Creating buyer_tutorials table in MySQL...');

  const sql = `
CREATE TABLE IF NOT EXISTS buyer_tutorials (
  id VARCHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  video_url VARCHAR(500) NOT NULL,
  youtube_video_id VARCHAR(50) NULL,
  thumbnail_url VARCHAR(500) NULL,
  category VARCHAR(100) NOT NULL DEFAULT 'General',
  display_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_category (category),
  INDEX idx_display_order (display_order),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql.replace(/\n/g, ' ')}"`);
  console.log('Create table output:', res.stdout, res.stderr);

  // Check if rows exist, if not insert sample tutorials
  const countRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -N -e "SELECT COUNT(*) FROM buyer_tutorials;"`);
  const count = parseInt(countRes.stdout.trim() || '0', 10);
  console.log('Existing tutorials count:', count);

  if (count === 0) {
    console.log('Seeding initial tutorial videos...');
    const seedSql = `
INSERT INTO buyer_tutorials (id, title, description, video_url, youtube_video_id, thumbnail_url, category, display_order, is_active) VALUES
(UUID(), 'How to Create a Google Play Store Campaign', 'Step-by-step guide on creating 5-star rating & app install campaigns for your Android app.', 'https://youtu.be/T9JNJwwDKSw', 'T9JNJwwDKSw', 'https://img.youtube.com/vi/T9JNJwwDKSw/hqdefault.jpg', 'Play Store', 1, 1),
(UUID(), 'How to Boost YouTube Video Views & Engagement', 'Learn how to configure watch-time, likes, subscribers and custom AI comments.', 'https://youtu.be/kM2wzMVDbhc', 'kM2wzMVDbhc', 'https://img.youtube.com/vi/kM2wzMVDbhc/hqdefault.jpg', 'YouTube', 2, 1),
(UUID(), 'How to Rank Higher on Google Maps & Local Search', 'Get verified 5-star customer reviews and boost your local business presence on Google Maps.', 'https://youtu.be/ZCe_jTS7NpQ', 'ZCe_jTS7NpQ', 'https://img.youtube.com/vi/ZCe_jTS7NpQ/hqdefault.jpg', 'Google Maps', 3, 1),
(UUID(), 'How to Add Funds to Wallet via UPI / QR Code', 'Quick tutorial on topping up your buyer balance instantly using Razorpay UPI or Bank Transfer.', 'https://youtu.be/T9JNJwwDKSw', 'T9JNJwwDKSw', 'https://img.youtube.com/vi/T9JNJwwDKSw/hqdefault.jpg', 'Wallet & Billing', 4, 1);
`;
    const seedRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${seedSql.replace(/\n/g, ' ')}"`);
    console.log('Seed output:', seedRes.stdout, seedRes.stderr);
  }

  const check = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, title, category, display_order, is_active FROM buyer_tutorials ORDER BY display_order ASC;"`);
  console.log('=== CURRENT BUYER TUTORIALS IN DB ===\n', check.stdout);

  ssh.dispose();
}

run().catch(console.error);
