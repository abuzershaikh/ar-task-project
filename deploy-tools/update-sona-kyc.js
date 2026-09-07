const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function updateSonaKyc() {
  try {
    await ssh.connect({ host: '65.20.77.112', username: 'root', password: 'G8u$RW{5m46buXgw' });

    console.log('Updating KYC profile for Sona...');
    const workerId = '52695909-751a-48ef-b8b4-3e77e1d8558e';
    const updateSql = `
      UPDATE kyc_profiles 
      SET 
        bank_name = 'HDFC Bank',
        account_number = '50100234567890',
        ifsc_code = 'HDFC0001234',
        upi_id = 'sona@okhdfcbank',
        paypal_id = 'sonathe333@gmail.com',
        status = 'SUBMITTED',
        full_name = 'Sona',
        submitted_at = NOW()
      WHERE worker_id = '${workerId}';
    `;
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${updateSql.replace(/\n/g, ' ')}"`);
    console.log('KYC Profile update result:', res.stdout || res.stderr || 'Success');

    // Also update worker.profile bankDetails
    const workerSql = `
      UPDATE workers 
      SET 
        kycStatus = 'SUBMITTED',
        profile = JSON_SET(COALESCE(profile, '{}'), '$.bankDetails', JSON_OBJECT(
          'bankName', 'HDFC Bank',
          'accountNumber', '50100234567890',
          'ifscCode', 'HDFC0001234',
          'upiId', 'sona@okhdfcbank',
          'paypalId', 'sonathe333@gmail.com',
          'status', 'SUBMITTED'
        ))
      WHERE id = '${workerId}';
    `;
    const wRes = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${workerSql.replace(/\n/g, ' ')}"`);
    console.log('Worker table update result:', wRes.stdout || wRes.stderr || 'Success');

    // Verify
    const verify = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT worker_id, status, bank_name, account_number, ifsc_code, upi_id, paypal_id FROM kyc_profiles WHERE worker_id='${workerId}';"`);
    console.log('Verified KYC:\n', verify.stdout);

  } catch (err) {
    console.error(err);
  } finally {
    ssh.dispose();
  }
}

updateSonaKyc();
