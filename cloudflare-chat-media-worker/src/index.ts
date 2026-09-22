/**
 * EarnPost Cloudflare Chat Support Media Worker
 * Dedicated worker for Support Chat Images, Photos, and Audio Voice Notes.
 * Backed by Cloudflare R2 Object Storage ("earnpost-chat-media").
 */

export interface Env {
  CHAT_MEDIA_BUCKET: R2Bucket;
  ENVIRONMENT?: string;
  MAX_UPLOAD_SIZE_MB?: string;
  PUBLIC_MEDIA_URL?: string;
}

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range, X-Requested-With',
  'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges, ETag',
};

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const pathname = url.pathname;

    // 1. CORS Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: CORS_HEADERS,
      });
    }

    try {
      // 2. Health check
      if (pathname === '/' || pathname === '/health') {
        return new Response(
          JSON.stringify({
            status: 'ok',
            service: 'earnpost-chat-media-worker',
            storage: env.CHAT_MEDIA_BUCKET ? 'R2: earnpost-chat-media' : 'unconfigured',
            version: '1.0.0',
            timestamp: new Date().toISOString(),
          }),
          {
            status: 200,
            headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
          }
        );
      }

      // 3. Media Upload (POST /upload or POST /api/upload)
      if (request.method === 'POST' && (pathname === '/upload' || pathname === '/api/upload')) {
        return await handleUpload(request, env);
      }

      // 4. Media Download / Streaming (GET /media/:filename, GET /image/:filename, GET /audio/:filename)
      if (
        (request.method === 'GET' || request.method === 'HEAD') &&
        (pathname.startsWith('/media/') ||
          pathname.startsWith('/image/') ||
          pathname.startsWith('/audio/') ||
          pathname.startsWith('/files/'))
      ) {
        const filename = pathname.replace(/^\/(media|image|audio|files)\//, '');
        return await handleMediaStream(request, env, filename);
      }

      // 5. Delete Media (DELETE /media/:filename)
      if (request.method === 'DELETE' && (pathname.startsWith('/media/') || pathname.startsWith('/files/'))) {
        const filename = pathname.replace(/^\/(media|files)\//, '');
        if (env.CHAT_MEDIA_BUCKET) {
          await env.CHAT_MEDIA_BUCKET.delete(filename);
        }
        return new Response(JSON.stringify({ success: true, message: `Deleted ${filename}` }), {
          status: 200,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        });
      }

      return new Response(JSON.stringify({ error: 'Endpoint not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
      });
    } catch (err: any) {
      return new Response(
        JSON.stringify({
          success: false,
          error: err?.message || 'Internal Server Error',
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
        }
      );
    }
  },
};

/**
 * Handle multipart form-data or raw binary upload
 */
async function handleUpload(request: Request, env: Env): Promise<Response> {
  const contentType = request.headers.get('Content-Type') || '';
  let fileBuffer: ArrayBuffer | null = null;
  let filename = '';
  let mimeType = 'image/jpeg';

  if (contentType.includes('multipart/form-data')) {
    const formData = await request.formData();
    const file = (formData.get('file') ||
      formData.get('media') ||
      formData.get('image') ||
      formData.get('audio')) as File | null;

    if (!file) {
      return new Response(
        JSON.stringify({ success: false, error: 'No file provided in form-data' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } }
      );
    }

    fileBuffer = await file.arrayBuffer();
    mimeType = file.type || getMimeTypeFromFilename(file.name);
    const ext = getExtension(file.name) || getExtensionFromMime(mimeType);
    const prefix = getPrefixForMime(mimeType);
    filename = `${prefix}_${Date.now()}_${generateRandomString(8)}.${ext}`;
  } else {
    // Raw binary upload
    fileBuffer = await request.arrayBuffer();
    const url = new URL(request.url);
    const customName = url.searchParams.get('filename');
    mimeType = contentType || 'image/jpeg';
    const ext = customName ? getExtension(customName) : getExtensionFromMime(mimeType);
    const prefix = getPrefixForMime(mimeType);
    filename = `${prefix}_${Date.now()}_${generateRandomString(8)}.${ext}`;
  }

  if (!fileBuffer || fileBuffer.byteLength === 0) {
    return new Response(
      JSON.stringify({ success: false, error: 'Uploaded file is empty' }),
      { status: 400, headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } }
    );
  }

  // Save to R2 Bucket
  if (env.CHAT_MEDIA_BUCKET) {
    await env.CHAT_MEDIA_BUCKET.put(filename, fileBuffer, {
      httpMetadata: {
        contentType: mimeType,
        cacheControl: 'public, max-age=31536000, immutable',
      },
      customMetadata: {
        uploadedAt: new Date().toISOString(),
        size: fileBuffer.byteLength.toString(),
      },
    });
  } else {
    return new Response(
      JSON.stringify({ success: false, error: 'R2 CHAT_MEDIA_BUCKET is not configured' }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } }
    );
  }

  const publicBaseUrl = env.PUBLIC_MEDIA_URL || new URL(request.url).origin;
  const publicUrl = `${publicBaseUrl}/media/${filename}`;

  return new Response(
    JSON.stringify({
      success: true,
      url: publicUrl,
      publicUrl,
      filename,
      size: fileBuffer.byteLength,
      mimeType,
      message: 'Chat media uploaded successfully to Cloudflare R2',
    }),
    {
      status: 201,
      headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
    }
  );
}

/**
 * Handle streaming of media (supports 206 Partial Content for audio voice notes & video)
 */
async function handleMediaStream(request: Request, env: Env, filename: string): Promise<Response> {
  if (!env.CHAT_MEDIA_BUCKET) {
    return new Response(JSON.stringify({ error: 'R2 CHAT_MEDIA_BUCKET not configured' }), {
      status: 503,
      headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
    });
  }

  const rangeHeader = request.headers.get('Range');
  const object = await env.CHAT_MEDIA_BUCKET.get(filename, {
    range: rangeHeader ? parseRangeHeader(rangeHeader) : undefined,
    onlyIf: request.headers,
  });

  if (!object) {
    return new Response(JSON.stringify({ error: `File '${filename}' not found` }), {
      status: 404,
      headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
    });
  }

  const headers = new Headers();
  object.writeHttpMetadata(headers);
  headers.set('etag', object.httpEtag);
  headers.set('Accept-Ranges', 'bytes');
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Cache-Control', 'public, max-age=31536000, immutable');

  const mime = headers.get('Content-Type') || getMimeTypeFromFilename(filename);
  headers.set('Content-Type', mime);

  if (rangeHeader && object.range) {
    // 206 Partial Content
    const range = object.range as { offset: number; length?: number };
    headers.set('Content-Range', `bytes ${range.offset}-${range.offset + (range.length ?? 0) - 1}/${object.size}`);
    return new Response(object.body as any, {
      status: 206,
      headers,
    });
  }

  headers.set('Content-Length', object.size.toString());
  if (request.method === 'HEAD') {
    return new Response(null, {
      status: 200,
      headers,
    });
  }
  return new Response(object.body as any, {
    status: 200,
    headers,
  });
}

function getExtension(filename: string): string {
  const parts = filename.split('.');
  return parts.length > 1 ? parts.pop()!.toLowerCase() : '';
}

function getExtensionFromMime(mime: string): string {
  switch (mime) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'audio/mp4':
    case 'audio/m4a':
      return 'm4a';
    case 'audio/mpeg':
    case 'audio/mp3':
      return 'mp3';
    case 'audio/wav':
      return 'wav';
    case 'audio/aac':
      return 'aac';
    case 'audio/ogg':
      return 'ogg';
    default:
      return 'bin';
  }
}

function getPrefixForMime(mime: string): string {
  if (mime.startsWith('image/')) return 'chat_img';
  if (mime.startsWith('audio/')) return 'chat_audio';
  return 'chat_media';
}

function getMimeTypeFromFilename(filename: string): string {
  const ext = getExtension(filename);
  switch (ext) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'm4a':
    case 'mp4a':
      return 'audio/mp4';
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'aac':
      return 'audio/aac';
    case 'ogg':
      return 'audio/ogg';
    default:
      return 'application/octet-stream';
  }
}

function generateRandomString(length: number): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

function parseRangeHeader(rangeHeader: string): R2Range | undefined {
  const match = rangeHeader.match(/bytes=(\d+)-(\d+)?/);
  if (!match) return undefined;
  const offset = parseInt(match[1], 10);
  const end = match[2] ? parseInt(match[2], 10) : undefined;
  const length = end !== undefined ? end - offset + 1 : undefined;
  return { offset, length };
}
