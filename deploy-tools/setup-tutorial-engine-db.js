const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connected to VPS. Setting up `tutorials` table in MySQL...');

  const sql = `
CREATE TABLE IF NOT EXISTS tutorials (
  id VARCHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  video_url VARCHAR(1000) NOT NULL,
  youtube_video_id VARCHAR(64) NULL,
  thumbnail_url VARCHAR(1000) NULL,
  category VARCHAR(100) NOT NULL DEFAULT 'General',
  tags TEXT NULL,
  target_audience VARCHAR(20) NOT NULL DEFAULT 'buyer',
  display_order INT NOT NULL DEFAULT 0,
  duration VARCHAR(50) NULL DEFAULT '2:30',
  views_count INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  INDEX idx_category (category),
  INDEX idx_target_audience (target_audience),
  INDEX idx_display_order (display_order),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

  const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${sql.replace(/\n/g, ' ')}"`);
  console.log('Create table output:', res.stdout, res.stderr);

  // Check if rows exist, if not insert rich seed tutorials
  const countRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -N -e "SELECT COUNT(*) FROM tutorials;"`);
  const count = parseInt(countRes.stdout.trim() || '0', 10);
  console.log('Existing tutorials count:', count);

  if (count === 0) {
    console.log('Seeding initial tutorials for Buyer & Worker...');
    const seedSql = `
INSERT INTO tutorials (id, title, description, video_url, youtube_video_id, thumbnail_url, category, tags, target_audience, display_order, duration, is_active) VALUES
(UUID(), 'How to Create a Google Play Store Campaign', 'Master step-by-step app promotion, keyword targeting, 5-star rating and installs setup.', 'https://youtu.be/T9JNJwwDKSw', 'T9JNJwwDKSw', 'https://img.youtube.com/vi/T9JNJwwDKSw/hqdefault.jpg', 'Play Store', 'play store, app install, android, review, rating, campaign', 'buyer', 1, '3:15', 1),
(UUID(), 'How to Boost YouTube Video Views & Watch Time', 'Learn how to configure organic watch-time retention, likes, subscriber growth and AI comments.', 'https://youtu.be/kM2wzMVDbhc', 'kM2wzMVDbhc', 'https://img.youtube.com/vi/kM2wzMVDbhc/hqdefault.jpg', 'YouTube', 'youtube, views, watch time, subscriber, retention, video', 'buyer', 2, '4:20', 1),
(UUID(), 'How to Rank #1 on Google Maps & Local Business', 'Get genuine verified 5-star customer reviews and skyrocket your local business presence.', 'https://youtu.be/ZCe_jTS7NpQ', 'ZCe_jTS7NpQ', 'https://img.youtube.com/vi/ZCe_jTS7NpQ/hqdefault.jpg', 'Google Maps', 'google maps, local seo, gmb, business reviews, ranking', 'buyer', 3, '5:00', 1),
(UUID(), 'How to Add Funds to Wallet via UPI & QR Code', 'Quick tutorial on topping up your buyer balance instantly using Razorpay UPI, GPay or PhonePe.', 'https://youtu.be/T9JNJwwDKSw', 'T9JNJwwDKSw', 'https://img.youtube.com/vi/T9JNJwwDKSw/hqdefault.jpg', 'Wallet & Billing', 'wallet, payment, upi, qr code, billing, funds, deposit', 'buyer', 4, '2:10', 1),
(UUID(), 'How to Track Realtime Campaign Analytics & Reports', 'Monitor worker submissions, verify screenshots, check proofs and export PDF reports.', 'https://youtu.be/kM2wzMVDbhc', 'kM2wzMVDbhc', 'https://img.youtube.com/vi/kM2wzMVDbhc/hqdefault.jpg', 'Campaigns', 'analytics, tracking, reports, proof, submissions, live order', 'buyer', 5, '3:45', 1),
(UUID(), 'Worker Guide: How to Complete YouTube Tasks Properly', 'Complete watch-time requirement, like the video and submit correct screenshot proof.', 'https://youtu.be/T9JNJwwDKSw', 'T9JNJwwDKSw', 'https://img.youtube.com/vi/T9JNJwwDKSw/hqdefault.jpg', 'Tasks Guide', 'worker, youtube task, watch time, earnings, proof', 'worker', 1, '3:30', 1),
(UUID(), 'Worker Guide: How to Withdraw Money to Bank / UPI', 'Step by step withdrawal tutorial for workers to get money in bank account within 24 hours.', 'https://youtu.be/ZCe_jTS7NpQ', 'ZCe_jTS7NpQ', 'https://img.youtube.com/vi/ZCe_jTS7NpQ/hqdefault.jpg', 'Earnings & Payout', 'worker, withdrawal, upi, bank transfer, payout, money', 'worker', 2, '2:45', 1);
`;
    const seedRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${seedSql.replace(/\n/g, ' ')}"`);
    console.log('Seed output:', seedRes.stdout, seedRes.stderr);
  }

  const check = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, title, category, target_audience, display_order, is_active FROM tutorials ORDER BY display_order ASC;"`);
  console.log('=== CURRENT TUTORIALS IN DB ===\n', check.stdout);

  ssh.dispose();
}

run().catch(console.error);
