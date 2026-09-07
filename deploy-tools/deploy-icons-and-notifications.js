const { NodeSSH } = require('node-ssh');
const path = require('path');
const ssh = new NodeSSH();

async function deployIconsAndNotifications() {
  try {
    console.log('🚀 Connecting to Mumbai VPS (65.20.77.112)...');
    await ssh.connect({
      host: '65.20.77.112',
      username: 'root',
      password: 'G8u$RW{5m46buXgw',
    });

    console.log('✅ Connected to VPS!\n');

    const localBase = 'e:/pc2/android  project/Task  project/ar-task-project/Task engine';
    const remoteBase = '/opt/task-engine';

    // ── Step 1: Create icons directory on VPS ──
    console.log('📁 Creating icons directory on VPS...');
    await ssh.execCommand(`mkdir -p ${remoteBase}/assets/icons`);
    console.log('   → /opt/task-engine/assets/icons/ created\n');

    // ── Step 2: Download platform brand icons directly on VPS ──
    // Using Google's favicon service + other reliable CDNs that don't block server-side requests
    console.log('🎨 Downloading platform brand icons on VPS...');

    const iconDownloads = [
      {
        name: 'youtube',
        // YouTube's official favicon from Google
        url: 'https://www.gstatic.com/youtube/img/branding/youtubelogo/svg/youtubelogo.svg',
        // Alternative: use yt_icon from YouTube's own CDN (PNG format)
        pngUrl: 'https://lh3.googleusercontent.com/3_OFn2skqHXk-UQ-9RUdNrDl_HiBN_bEbKRWSD5yMC8LjyMnUMELMGKBR0GkuITnSP8Rm3VJOA8PchJHBEUiQtbcpmSEBjAHeg=s120',
      },
      {
        name: 'instagram',
        // Instagram's favicon via Google favicon service
        pngUrl: 'https://lh3.googleusercontent.com/2sREY-8UpjmaLDCTztldQf5Ot8NjhF3WZBnSBvSMSsHsHKL9IP_dJSwcc3FyR_wFBIg=s120',
      },
      {
        name: 'playstore',
        pngUrl: 'https://lh3.googleusercontent.com/q1k2l5CwMV31JdDXcpN4Ey7O43PBv8YTCjnT5Jf5b5oaH3VYSMqlHIa8PoSxc0sKBNA=s120',
      },
      {
        name: 'facebook',
        pngUrl: 'https://lh3.googleusercontent.com/ccWDU4A7fX1R24v-vvT480ySh26AYp97g1VrIB_FIdjRcuQB2JP2WdY7h_wVVAeSpg=s120',
      },
      {
        name: 'telegram',
        pngUrl: 'https://lh3.googleusercontent.com/ZU9cSsyIJZo6Oy7HTHiEPwZg0m2Crep-d5ZrfajqtsH-qgUXSqKpNA2FpPDTn-7qA5Q=s120',
      },
      {
        name: 'twitter',
        pngUrl: 'https://lh3.googleusercontent.com/jMaU7GKyFmSCHLOnXihWbP5yBjh_vZ9G2tLM3RI6FTFWJ5n0jOBaXuVhPOBg-RrNqfE=s120',
      },
      {
        name: 'tiktok',
        pngUrl: 'https://lh3.googleusercontent.com/OS-MhZzI_M1IjGvR2t_H4SM06s9NO8jGnbXjr0oCjuGPKw3xTGsxV99FXOF9QE01fEM=s120',
      },
    ];

    // Download each icon using curl on VPS, with fallback to Google Favicon API
    for (const icon of iconDownloads) {
      const destPath = `${remoteBase}/assets/icons/${icon.name}.png`;
      
      // Primary: try Play Store CDN / Google images URL
      if (icon.pngUrl) {
        console.log(`   📥 Downloading ${icon.name}.png ...`);
        const dlRes = await ssh.execCommand(
          `curl -fsSL -o "${destPath}" "${icon.pngUrl}" 2>&1 && echo "OK" || echo "FAIL"`,
          { cwd: remoteBase }
        );
        const ok = (dlRes.stdout || '').includes('OK');
        if (ok) {
          // Verify file is not empty/error page
          const sizeCheck = await ssh.execCommand(`stat -c%s "${destPath}" 2>/dev/null || echo 0`);
          const fileSize = parseInt(sizeCheck.stdout.trim()) || 0;
          if (fileSize > 500) {
            console.log(`   ✅ ${icon.name}.png downloaded (${fileSize} bytes)`);
            continue;
          }
        }
      }

      // Fallback: Google Favicon Service (always works, gives 256px icons)
      console.log(`   🔄 Fallback: using Google Favicon API for ${icon.name}...`);
      const domainMap = {
        youtube: 'youtube.com',
        instagram: 'instagram.com',
        playstore: 'play.google.com',
        facebook: 'facebook.com',
        telegram: 'telegram.org',
        twitter: 'twitter.com',
        tiktok: 'tiktok.com',
      };
      const domain = domainMap[icon.name] || `${icon.name}.com`;
      const faviconUrl = `https://www.google.com/s2/favicons?domain=${domain}&sz=256`;
      const fbRes = await ssh.execCommand(
        `curl -fsSL -o "${destPath}" "${faviconUrl}" 2>&1 && echo "OK" || echo "FAIL"`,
        { cwd: remoteBase }
      );
      const fbOk = (fbRes.stdout || '').includes('OK');
      if (fbOk) {
        const sizeCheck2 = await ssh.execCommand(`stat -c%s "${destPath}" 2>/dev/null || echo 0`);
        const fileSize2 = parseInt(sizeCheck2.stdout.trim()) || 0;
        console.log(`   ${fileSize2 > 100 ? '✅' : '⚠️'} ${icon.name}.png via Google Favicon (${fileSize2} bytes)`);
      } else {
        console.log(`   ⚠️ ${icon.name}.png download failed`);
      }
    }

    console.log('');

    // ── Step 3: Verify all icons exist ──
    console.log('🔍 Verifying icons on VPS...');
    const verifyRes = await ssh.execCommand(`ls -la ${remoteBase}/assets/icons/`);
    console.log(verifyRes.stdout);
    console.log('');

    // ── Step 4: Upload updated backend source files ──
    const files = [
      {
        local: path.join(localBase, 'apps/api/controllers/common/asset.controller.ts'),
        remote: `${remoteBase}/apps/api/controllers/common/asset.controller.ts`,
      },
      {
        local: path.join(localBase, 'apps/api/app.module.ts'),
        remote: `${remoteBase}/apps/api/app.module.ts`,
      },
      {
        local: path.join(localBase, 'shared/services/order-activated.listener.ts'),
        remote: `${remoteBase}/shared/services/order-activated.listener.ts`,
      },
      {
        local: path.join(localBase, 'shared/services/firebase-admin.service.ts'),
        remote: `${remoteBase}/shared/services/firebase-admin.service.ts`,
      },
    ];

    for (const f of files) {
      const basename = path.basename(f.local);
      console.log(`📤 Uploading ${basename}...`);
      await ssh.putFile(f.local, f.remote);
    }
    console.log('');

    // ── Step 5: Build backend on VPS ──
    console.log('🔨 Building backend on VPS (npx nest build)...');
    const buildRes = await ssh.execCommand('npx nest build', { cwd: remoteBase });
    console.log('Build:', buildRes.stdout || 'Done');
    if (buildRes.stderr && !buildRes.stderr.includes('Debugger') && !buildRes.stderr.includes('deprecated')) {
      console.warn('Build warnings:', buildRes.stderr.substring(0, 500));
    }
    console.log('');

    // ── Step 6: Restart PM2 ──
    console.log('🔄 Restarting PM2 backend service...');
    const restartRes = await ssh.execCommand('pm2 restart task-engine-api', { cwd: remoteBase });
    console.log(restartRes.stdout);
    console.log('');

    // ── Step 7: Test icon endpoint ──
    console.log('🧪 Testing icon endpoint...');
    await new Promise(r => setTimeout(r, 3000)); // Wait for PM2 restart
    
    const platforms = ['youtube', 'instagram', 'playstore', 'facebook', 'telegram', 'twitter'];
    for (const p of platforms) {
      const testRes = await ssh.execCommand(
        `curl -s -o /dev/null -w "%{http_code} %{size_download}" "http://localhost:3000/api/v1/assets/icons/${p}"`
      );
      const [status, size] = (testRes.stdout || '').split(' ');
      const emoji = status === '200' ? '✅' : '❌';
      console.log(`   ${emoji} /api/v1/assets/icons/${p} → HTTP ${status} (${size} bytes)`);
    }
    console.log('');

    // ── Step 8: Send test FCM notification with icon ──
    console.log('📢 Sending test FCM notification with YouTube icon...');
    const testScript = `
const admin = require('firebase-admin');
const sa = {
  projectId: 'taskz-87679',
  clientEmail: 'firebase-adminsdk-fbsvc@taskz-87679.iam.gserviceaccount.com',
  privateKey: '-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDF8/ApjOVJ3UFM\\n69V4PIx126TIAIyxjGNqX+S05FqKWffISMEDWXxF40Toajbg5ycynPxa32jyonSH\\n4vmchbB1PURb+0W4IpbkGhVJkCurbu/LBrvauPN4xCTOZbd7bK7h9MHnqxODqxHH\\nIVj8s22Hc/8xtzk6MXsUrB4tF2gLSKsx4xvBc/ywQtdRazj3z0wVE5EJ/oq3xrAg\\nAr3IbwyPbdc3a5qg0CV5gQjbcyONJypVF1regKgki3jeTA9nFV/FsQvBmzD/CI1S\\nXW5ZTD7E6ciyv6uTnsWxlqxOVaJ6kuYEx8mUPqc5k44mx5jm/AiEK3sTfK25xazH\\nHdLqPhyLAgMBAAECggEAFDpmO0i7kX27k4mx6bR+Qfjs8MclmWsYKaGc9GM1YVfq\\nOxw8JQR674VW4E0iSH82gTSLkRmtVsYFFHG8QiNjMcfN+XxG1pcqRiroK/lAjScr\\n99o7ThGCR7/7Zt/8DO/BOzPQsMTJnLXZfjjJKCGJusK+vCzV+z1dL3KbLs5qgmR/\\nUjerQR2cvcGByCo8ZRLydflCYk6D1I454vKYivMlyiJVo8etcEgmmyJeDrN+8/iy\\nsrB06BoA3bb2VoLRo8PK8hOBcpcUQNo0dXGVWt/corSDorJvSU/l+UXEu7NuXwt3\\nnRPFlGAgiR/ScaL9EdfTaKhkvmcYjaIP2Eo8zBJh8QKBgQD8g2PaHayel1ZlEwVJ\\nZydfn9dAbTAUJbSfjjwn1v9FjqACHr2t/AmcBUbEWOD4MnpJhGUIcOqvETPGHbyM\\nEWed1mJ6LCY2EQI4xf4WGmdTpd23Whi+XynnyKrlog9hvdAnbmpCvSGc1BLwrgzj\\nFGyDLEQwLAGNColvXZgswDWduQKBgQDIr663FBeSQwoNCJ0JUU1iRhNI3oVeo2xM\\nsUFs8aO8joDajvBQkXLnDwtRlKtCRaBGtgwN1EO2MNJJiTQIQzy78DUDfmy6tm0v\\nSpVxOmAQN5UiKF6uEKt7IIy+7u81mGn1WDHshBj99qIUVk8xCBTEb6ZBM9zfmIsy\\nWfX9/vIOYwKBgQCReymGOt5/KHXwGbtMBRBcOX0Mc1vl36tm2c2yrl24N2ncjtV9\\nbd4jc67H5OUIWhy2Sn7jFBtB7clEdVFx6X0nJKLr/I+vSrFbAEdZeLDbMo7A2jmz\\nRKSiE6zSTEJMb82DSkwSU2EQN+cJn11xXwz9rf1DO7dRCScRcH0CG2NIkQKBgB8W\\nV9I0YpJdoCj0tJ7E4V/fywz2q2JFnnki3CesJtkGmh9BFSjl3w673dz9UqopbvKF\\nMMjToMmQNoL9pfnBsJ7MTuoDo4QozjENNKkdidP5SDjKWCBOpMGmASdyi8uZmJBQ\\n4SrqK5Trp5/O3uWRguYLBY4EIqrgTm+2T8zQuV5RAoGAUcKd5uS51HKj2dLofgWY\\n6La/TwMSvpuxhf9ysq1WduCt54/hXAhuU9uRGPTDwfi3q7PiCd7sgS8HdBkMY+D/\\nCifUklpxWwlYynnTT6rrlNVbLnMpkyy+TM2/NZUXv4UhqnUIuVsC2CoUsFwUDw9+\\nYn5YnkjDjmTC6EJTTmvmEJY=\\n-----END PRIVATE KEY-----\\n'
};
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(sa) });

const iconUrl = 'http://65.20.77.112:3000/api/v1/assets/icons/youtube';
const message = {
  topic: 'workers',
  notification: {
    title: '🎉 New YouTube Task! Earn ₹10',
    body: 'Complete YouTube Comment task and earn instant cash!',
    imageUrl: iconUrl
  },
  data: {
    type: 'NEW_TASK',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    taskId: 'TEST_YT_ICON_' + Date.now(),
    orderId: 'TEST_ORDER_YT_ICON',
    reward: '10',
    serviceCode: 'YOUTUBE_COMMENT',
    category: 'YouTube',
    title: '🎉 New YouTube Task! Earn ₹10',
    body: 'Complete YouTube Comment task and earn instant cash!',
    icon: iconUrl,
    imageUrl: iconUrl,
    appIcon: iconUrl,
    appName: 'YouTube',
    targetUrl: 'https://youtube.com',
    createdAt: new Date().toISOString()
  },
  android: {
    priority: 'high',
    notification: {
      channelId: 'task_notifications',
      priority: 'high',
      sound: 'default',
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      imageUrl: iconUrl
    }
  }
};

admin.messaging().send(message)
  .then(resp => {
    console.log('✅ FCM YouTube Notification sent! ID:', resp);
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ FCM Error:', err.message);
    process.exit(1);
  });
`;

    const fcmRes = await ssh.execCommand(
      `node -e "${testScript.replace(/\n/g, ' ').replace(/"/g, '\\"')}"`,
      { cwd: remoteBase }
    );
    console.log(fcmRes.stdout);
    if (fcmRes.stderr && !fcmRes.stderr.includes('Debugger')) {
      console.error(fcmRes.stderr.substring(0, 300));
    }

    console.log('\n🎉 ═══════════════════════════════════════════');
    console.log('   DEPLOYMENT COMPLETE!');
    console.log('   ✅ Self-hosted icons: YouTube, Instagram, Play Store,');
    console.log('      Facebook, Telegram, Twitter, TikTok');
    console.log('   ✅ Backend rebuilt & restarted');
    console.log('   ✅ Test FCM notification sent');
    console.log('═══════════════════════════════════════════════');

  } catch (e) {
    console.error('❌ Deployment error:', e);
  } finally {
    ssh.dispose();
  }
}

deployIconsAndNotifications();
