# EarnPost Cloudflare Media Worker (Audio & Video Storage)

High-performance Cloudflare Worker with Cloudflare R2 bucket binding for storing voice audio guides and streaming tutorial media directly to EarnPost Worker & Admin apps.

---

## Features
- **Upload Voice Notes / Audio**: `POST /upload` (supports multipart/form-data audio and binary streams).
- **Zero-Latency Audio Streaming**: `GET /audio/:filename` with `HTTP 206 Range` support for instant seeking.
- **R2 Cloudflare Object Storage**: Ultra low cost and zero egress fees.
- **Full CORS enabled**: Direct upload and playback from Flutter mobile apps and web.

---

## Quick Deployment Steps

### 1. Install Wrangler CLI
```bash
cd "d:\AR Task Project\cloudflare-media-worker"
npm install
```

### 2. Login to your Cloudflare Account
```bash
npx wrangler login
```

### 3. Create Cloudflare R2 Storage Bucket
```bash
npx wrangler r2 bucket create earnpost-media
```

### 4. Deploy the Worker
```bash
npx wrangler deploy
```

Once deployed, your Cloudflare Worker URL will be displayed (e.g. `https://earnpost-media-worker.<your-subdomain>.workers.dev`).
Set this URL in the Admin App configuration or environment settings.

---

## API Endpoints

### 1. Upload Audio Voice Note
- **URL**: `POST https://<your-worker>.workers.dev/upload`
- **Body**: `multipart/form-data` with key `file` (audio `.m4a`, `.mp3`, `.wav`)
- **Response**:
```json
{
  "success": true,
  "url": "https://<your-worker>.workers.dev/audio/audio_1723812345_a1b2c3.m4a",
  "filename": "audio_1723812345_a1b2c3.m4a",
  "size": 65536,
  "mimeType": "audio/mp4"
}
```

### 2. Stream Audio
- **URL**: `GET https://<your-worker>.workers.dev/audio/audio_1723812345_a1b2c3.m4a`
- Directly playable in any mobile / web audio player.
