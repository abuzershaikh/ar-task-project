const { NodeSSH } = require('node-ssh');
const ssh = new NodeSSH();

async function run() {
  await ssh.connect({
    host: '65.20.77.112',
    username: 'root',
    password: 'G8u$RW{5m46buXgw',
  });

  const apiRes = await ssh.execCommand(`curl -s -H "x-user-email: brandnew_worker@gmail.com" -H "x-user-id: newworker999" -H "x-user-role: WORKER" http://127.0.0.1:3000/api/v1/worker/tasks/available`);
  const data = JSON.parse(apiRes.stdout);

  console.log(`=== AUDIT OF ALL ${data.tasks?.length} AVAILABLE TASKS ===`);
  for (const t of (data.tasks || [])) {
    const type = (t.taskType || t.type || '').toLowerCase();
    const urlStr = (t.targetUrl || t.url || t.requirements?.targetUrl || '').toLowerCase();
    const rawPlat = (t.platform || t.requirements?.platform || '').toLowerCase().trim();

    // Updated TaskFeedCard _getPlatform logic:
    let platform = 'google_maps';
    if (type.includes('youtube') || type.includes('yt_') || urlStr.includes('youtu.be') || urlStr.includes('youtube.com') || rawPlat === 'youtube') {
      platform = 'youtube';
    } else if (type.includes('google_business') || type.includes('google_maps') || type.includes('gmb') || urlStr.includes('maps.google') || urlStr.includes('goo.gl/maps') || urlStr.includes('maps.app.goo.gl') || urlStr.includes('share.google') || rawPlat === 'google_maps' || rawPlat === 'google_business' || rawPlat === 'google') {
      platform = 'google_maps';
    } else if (type.includes('instagram') || type.includes('ig_') || urlStr.includes('instagram.com') || rawPlat === 'instagram') {
      platform = 'instagram';
    } else if (type.includes('app_install') || type.includes('playstore') || type.includes('play_store') || urlStr.includes('play.google.com') || rawPlat === 'playstore' || (type.includes('install') && !type.includes('instagram'))) {
      platform = 'playstore';
    }

    // Updated TaskFeedCard _isAppInstall logic:
    const isAppInstall = (platform !== 'youtube' && platform !== 'instagram' && platform !== 'google_maps') &&
      (type.includes('app_install') || (type.includes('install') && !type.includes('instagram')));

    // Title preview:
    let title = t.requirements?.videoTitle || t.requirements?.appName || t.title || t.serviceTitle || 'Task';
    if (platform === 'youtube') {
      title = `Watch & Engage: ${t.requirements?.videoTitle || t.requirements?.title || 'YouTube Video'}`;
    } else if (isAppInstall) {
      title = `Install & Open: ${t.requirements?.appName || 'App'}`;
    }

    console.log(`[${platform.toUpperCase()}] ${t.id.slice(0, 8)} | Type: ${t.taskType} | isAppInstall: ${isAppInstall} | Title: "${title.slice(0, 50)}..."`);
  }

  ssh.dispose();
}

run().catch(console.error);
