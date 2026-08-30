const { Client } = require('ssh2');

const vpsConfig = {
  host: '65.20.77.112',
  port: 22,
  username: 'root',
  password: 'G8u$RW{5m46buXgw'
};

function runSSH(conn, command) {
  return new Promise((resolve, reject) => {
    conn.exec(command, (err, stream) => {
      if (err) return reject(err);
      let stdout = '';
      let stderr = '';
      stream.on('close', (code) => {
        resolve({ code, stdout, stderr });
      });
      stream.on('data', (data) => { stdout += data.toString(); });
      stream.stderr.on('data', (data) => { stderr += data.toString(); });
    });
  });
}

async function main() {
  const conn = new Client();
  await new Promise((resolve, reject) => {
    conn.on('ready', resolve).on('error', reject).connect(vpsConfig);
  });

  console.log('Connected to VPS!');

  // Check columns in kyc_profiles
  const kycCols = await runSSH(conn, `mysql -u taskapp -pTaskApp_Secure_2026_PW task_platform -e "DESCRIBE kyc_profiles;"`);
  console.log('kyc_profiles table columns:');
  console.log(kycCols.stdout);

  // Add missing columns to kyc_profiles
  const fixKyc = `
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS gender VARCHAR(50) NULL AFTER date_of_birth;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS address TEXT NULL AFTER gender;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS city VARCHAR(100) NULL AFTER address;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS state VARCHAR(100) NULL AFTER city;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS pincode VARCHAR(20) NULL AFTER state;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS country VARCHAR(100) NULL AFTER pincode;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS bank_name VARCHAR(255) NULL AFTER country;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS account_number VARCHAR(255) NULL AFTER bank_name;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(50) NULL AFTER account_number;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS upi_id VARCHAR(255) NULL AFTER ifsc_code;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS paypal_id VARCHAR(255) NULL AFTER upi_id;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP NULL AFTER paypal_id;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS reviewed_by VARCHAR(255) NULL AFTER submitted_at;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP NULL AFTER reviewed_by;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS rejection_reason TEXT NULL AFTER reviewed_at;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS expiry_date DATE NULL AFTER rejection_reason;
    ALTER TABLE kyc_profiles ADD COLUMN IF NOT EXISTS metadata JSON NULL AFTER expiry_date;
  `;

  const fixRes = await runSSH(conn, `mysql -u taskapp -pTaskApp_Secure_2026_PW task_platform -e "${fixKyc.replace(/\n/g, ' ')}"`);
  console.log('Applied fix to kyc_profiles:', fixRes.stdout || 'Done');
  if (fixRes.stderr) console.error('Stderr:', fixRes.stderr);

  // Check all other tables
  const descAll = await runSSH(conn, `mysql -u taskapp -pTaskApp_Secure_2026_PW task_platform -e "SHOW TABLES;"`);
  console.log('\nAll tables in task_platform:');
  console.log(descAll.stdout);

  conn.end();
}

main().catch(console.error);
