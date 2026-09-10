const https = require('https');

function extractVideoId(input) {
  if (!input) return null;
  const clean = input.trim();
  const regExp = /(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|shorts\/))([\w-]{11})/i;
  const match = clean.match(regExp);
  if (match && match[1]) return match[1];
  if (/^[\w-]{11}$/.test(clean)) return clean;
  return null;
}

function formatDuration(seconds) {
  if (seconds <= 0) return '0s';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (mins === 0) return `${secs}s`;
  if (secs === 0) return `${mins}m`;
  return `${mins}m ${secs}s`;
}

async function fetchInnertube(videoId, clientName = 'ANDROID_TESTSUITE', clientVersion = '1.9') {
  return new Promise((resolve) => {
    const postData = JSON.stringify({
      context: {
        client: {
          clientName: clientName,
          clientVersion: clientVersion,
          hl: 'en',
          gl: 'US'
        }
      },
      videoId: videoId
    });

    const req = https.request({
      hostname: 'www.youtube.com',
      port: 443,
      path: '/youtubei/v1/player?prettyPrint=false',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      },
      timeout: 5000
    }, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => {
        try {
          const j = JSON.parse(b);
          const details = j.videoDetails;
          if (details && details.lengthSeconds) {
            const secs = parseInt(details.lengthSeconds, 10);
            if (secs > 0) {
              const thumbs = details.thumbnail?.thumbnails;
              const thumb = (thumbs && thumbs.length > 0)
                ? thumbs[thumbs.length - 1].url
                : `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;

              resolve({
                success: true,
                videoId,
                title: details.title,
                author: details.author,
                durationSeconds: secs,
                thumbnail: thumb
              });
              return;
            }
          }
        } catch(e) {}
        resolve(null);
      });
    });

    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
    req.write(postData);
    req.end();
  });
}

async function fetchOembed(videoId) {
  return new Promise((resolve) => {
    https.get(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`, { timeout: 4000 }, (res) => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => {
        try {
          const j = JSON.parse(b);
          if (j.title) {
            resolve({
              title: j.title,
              author: j.author_name,
              thumbnail: j.thumbnail_url || `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`
            });
            return;
          }
        } catch(e) {}
        resolve(null);
      });
    }).on('error', () => resolve(null))
      .on('timeout', () => resolve(null));
  });
}

async function getVideoMetadata(input) {
  const videoId = extractVideoId(input);
  if (!videoId) {
    return { success: false, error: 'Invalid YouTube link or video ID' };
  }

  // 1. Try Innertube API (bypasses datacenter bot blocks)
  let result = await fetchInnertube(videoId, 'ANDROID_TESTSUITE', '1.9');
  
  // 2. Try secondary Innertube client if needed
  if (!result || !result.durationSeconds) {
    result = await fetchInnertube(videoId, 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', '2.0');
  }

  // 3. Complement with oEmbed if title or thumbnail missing
  let title = result?.title;
  let thumbnail = result?.thumbnail || `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
  if (!title) {
    const oembed = await fetchOembed(videoId);
    if (oembed) {
      title = oembed.title;
      if (oembed.thumbnail) thumbnail = oembed.thumbnail;
    }
  }
  if (!title) title = 'YouTube Video';

  let durationSeconds = result?.durationSeconds || 0;

  let requiredWatchSeconds = durationSeconds;
  let isCappedAt5Min = false;

  if (durationSeconds > 300) {
    requiredWatchSeconds = 300;
    isCappedAt5Min = true;
  } else if (durationSeconds <= 0) {
    durationSeconds = 60;
    requiredWatchSeconds = 60;
  }

  return {
    success: true,
    videoId,
    title,
    thumbnail,
    durationSeconds,
    durationFormatted: formatDuration(durationSeconds),
    requiredWatchSeconds,
    requiredWatchFormatted: formatDuration(requiredWatchSeconds),
    isCappedAt5Min,
  };
}

(async () => {
  const res = await getVideoMetadata('https://www.youtube.com/watch?v=sViKU1eitc4');
  console.log('Result for sViKU1eitc4:\n', res);
})();
