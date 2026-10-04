const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function main() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  console.log('Connected to VPS SSH.');

  const queries = [
    // Google Maps services
    `UPDATE service_catalog SET 
      category = 'Google Maps', 
      ai_generator_enabled = 1, 
      link_field_label = 'Google Link', 
      link_field_placeholder = 'https://maps.app.goo.gl/... or Google Maps listing link' 
     WHERE code = 'GOOGLE_BUSINESS_REVIEW';`,

    `UPDATE service_catalog SET 
      category = 'Google Maps', 
      ai_generator_enabled = 0, 
      link_field_label = 'Google Link', 
      link_field_placeholder = 'https://maps.app.goo.gl/... or Google Maps listing link' 
     WHERE code = 'GOOGLE_BUSINESS_RATING';`,

    // Play Store services
    `UPDATE service_catalog SET 
      category = 'Play Store', 
      ai_generator_enabled = 1, 
      link_field_label = 'Google Play Store App Link', 
      link_field_placeholder = 'https://play.google.com/store/apps/details?id=...' 
     WHERE code = 'PLAYSTORE_REVIEW';`,

    `UPDATE service_catalog SET 
      category = 'Play Store', 
      ai_generator_enabled = 0, 
      link_field_label = 'Google Play Store App Link', 
      link_field_placeholder = 'https://play.google.com/store/apps/details?id=...' 
     WHERE code = 'PLAYSTORE_RATING';`,

    // App Install
    `UPDATE service_catalog SET 
      category = 'App Install & Review', 
      ai_generator_enabled = 0, 
      link_field_label = 'Google Play Store App URL', 
      link_field_placeholder = 'https://play.google.com/store/apps/details?id=...' 
     WHERE code = 'APP_INSTALL';`,

    // YouTube services
    `UPDATE service_catalog SET 
      category = 'YouTube', 
      ai_generator_enabled = 1, 
      link_field_label = 'YouTube Video Link', 
      link_field_placeholder = 'https://www.youtube.com/watch?v=... or https://youtu.be/...' 
     WHERE code IN ('YOUTUBE_COMMENT', 'YOUTUBE_COMBO');`,

    `UPDATE service_catalog SET 
      category = 'YouTube', 
      ai_generator_enabled = 0, 
      link_field_label = 'YouTube Video Link', 
      link_field_placeholder = 'https://www.youtube.com/watch?v=... or https://youtu.be/...' 
     WHERE code IN ('YOUTUBE_LIKE', 'YOUTUBE_SUBSCRIBE');`,

    // Instagram services
    `UPDATE service_catalog SET 
      category = 'Instagram', 
      ai_generator_enabled = 1, 
      link_field_label = 'Instagram Post / Reel URL', 
      link_field_placeholder = 'https://www.instagram.com/p/... or /reel/...' 
     WHERE code IN ('INSTAGRAM_COMMENT', 'INSTAGRAM_COMBO');`,

    `UPDATE service_catalog SET 
      category = 'Instagram', 
      ai_generator_enabled = 0, 
      link_field_label = 'Instagram Profile URL / Username', 
      link_field_placeholder = 'https://instagram.com/your_username' 
     WHERE code = 'INSTAGRAM_FOLLOW';`,

    `UPDATE service_catalog SET 
      category = 'Instagram', 
      ai_generator_enabled = 0, 
      link_field_label = 'Instagram Post / Reel URL', 
      link_field_placeholder = 'https://www.instagram.com/p/... or /reel/...' 
     WHERE code = 'INSTAGRAM_LIKE';`,

    // Website Traffic
    `UPDATE service_catalog SET 
      category = 'Website Traffic', 
      ai_generator_enabled = 0, 
      link_field_label = 'Target Website Landing Page URL', 
      link_field_placeholder = 'https://yourwebsite.com/landing' 
     WHERE code = 'WEBSITE_VISITS';`,
  ];

  for (const q of queries) {
    const res = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "${q}"`);
    if (res.stderr) console.error('Error executing query:', res.stderr);
  }

  console.log('Queries executed. Checking updated table:');
  const verify = await ssh.execCommand(`mysql -u taskapp -ptaskapp_password task_platform -e "SELECT id, code, name, category, ai_generator_enabled, link_field_label FROM service_catalog ORDER BY category, code;"`);
  console.log(verify.stdout);

  ssh.dispose();
}

main().catch(console.error);
