import * as dns from 'dns';
import * as net from 'net';

export interface TaskIdentity {
    packageId?: string;
    normalizedUrl?: string;
    entityKey?: string;
}

/**
 * In-memory thread-safe cache for canonical URLs resolved from short-links.
 */
export const resolvedUrlCache = new Map<string, string>();

export function cacheResolvedUrl(shortUrl: string, destinationUrl: string): void {
    if (!shortUrl || !destinationUrl) return;
    const cleanShort = shortUrl.trim().toLowerCase();
    const cleanDest = destinationUrl.trim();
    if (cleanShort !== cleanDest.toLowerCase()) {
        resolvedUrlCache.set(cleanShort, cleanDest);
    }
}

/**
 * Universal extractor and normalizer for Task Identity (Package ID and Target URL).
 * Used across TaskQueryService, TaskCommandService, MatchingEngine, and NotificationEngine
 * to enforce the strict business rule:
 * "Agar user ne same app ka task kiya hai toh usko task na mile, aur YouTube/Instagram/Map URL
 * same hai already kar chuka hai toh task ka notification bhi na jaye."
 */
export function extractTaskIdentity(task: any): TaskIdentity {
    if (!task) return {};

    const reqs = task.requirements || {};
    const meta = task.metadata || {};

    // ── 1. Resolve Package ID (Play Store / App Install) ──────────────────────
    let pkg = (
        reqs.packageId ||
        meta.packageId ||
        reqs.appPackage ||
        reqs.packageName ||
        meta.appPackage ||
        meta.packageName ||
        task.packageId ||
        ''
    ).toString().trim().toLowerCase();

    // ── 2. Resolve Raw Target URL ─────────────────────────────────────────────
    let rawUrl = (
        reqs.targetUrl ||
        meta.targetUrl ||
        task.targetUrl ||
        reqs.url ||
        reqs.link ||
        reqs.playstoreUrl ||
        reqs.videoUrl ||
        meta.url ||
        meta.link ||
        task.url ||
        task.link ||
        ''
    ).toString().trim();

    // Check in-memory resolved URL cache (if short-link was expanded)
    if (rawUrl && resolvedUrlCache.has(rawUrl.toLowerCase())) {
        rawUrl = resolvedUrlCache.get(rawUrl.toLowerCase())!;
    }

    let normalizedUrl: string | undefined = undefined;

    if (rawUrl) {
        try {
            // Strip wrapper quotes or whitespace
            rawUrl = rawUrl.replace(/^["']|["']$/g, '').trim();
            const parsed = new URL(rawUrl.startsWith('http') ? rawUrl : `https://${rawUrl}`);
            const host = parsed.hostname.toLowerCase();
            const pathname = parsed.pathname.replace(/\/+$/, '');

            // ── (A) Google Play Store App Links ───────────────────────────────
            if (host.includes('google.com') && (pathname.includes('/store/apps/details') || pathname.includes('/store/apps'))) {
                const idParam = (parsed.searchParams.get('id') || '').toLowerCase().trim();
                if (idParam) {
                    if (!pkg) pkg = idParam;
                    normalizedUrl = `https://play.google.com/store/apps/details?id=${idParam}`;
                }
            } else if (rawUrl.startsWith('market://')) {
                const match = rawUrl.match(/id=([a-zA-Z0-9_.]+)/i);
                if (match && match[1]) {
                    const idParam = match[1].toLowerCase().trim();
                    if (!pkg) pkg = idParam;
                    normalizedUrl = `https://play.google.com/store/apps/details?id=${idParam}`;
                }
            }
            // ── (B) YouTube Links (Watch, Short, Shorts, Embed, Live, Channel) ───
            else if (host.includes('youtube.com') || host.includes('youtu.be')) {
                // Check 11-char video ID across all YouTube URL variations
                const ytVideoMatch = rawUrl.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?|shorts|live)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i);
                if (ytVideoMatch && ytVideoMatch[1]) {
                    const videoId = ytVideoMatch[1].trim();
                    normalizedUrl = `https://www.youtube.com/watch?v=${videoId}`;
                } else if (pathname.includes('/@')) {
                    const channelMatch = pathname.match(/\/(@[^\/\?]+)/i);
                    const channelName = channelMatch ? channelMatch[1].toLowerCase() : pathname.toLowerCase();
                    normalizedUrl = `https://www.youtube.com/${channelName}`;
                } else if (pathname.includes('/channel/') || pathname.includes('/c/')) {
                    normalizedUrl = `https://www.youtube.com${pathname.toLowerCase()}`;
                } else {
                    normalizedUrl = `https://www.youtube.com${pathname.toLowerCase()}`;
                }
            }
            // ── (C) Instagram Links (Post, Reel, Story, User Profile) ───────────
            else if (host.includes('instagram.com')) {
                // Post or Reel: instagram.com/p/{code} or instagram.com/reel/{code} or instagram.com/reels/{code}
                const igCodeMatch = pathname.match(/\/(?:p|reel|reels)\/([A-Za-z0-9_-]+)/i);
                if (igCodeMatch && igCodeMatch[1]) {
                    const shortcode = igCodeMatch[1].trim();
                    normalizedUrl = `https://www.instagram.com/p/${shortcode}`;
                } else {
                    // Profile URL: instagram.com/{username}
                    const userMatch = pathname.match(/^\/([A-Za-z0-9_.]+)/i);
                    if (userMatch && userMatch[1] && !['explore', 'direct', 'accounts', 'stories'].includes(userMatch[1].toLowerCase())) {
                        normalizedUrl = `https://www.instagram.com/${userMatch[1].toLowerCase()}`;
                    } else {
                        normalizedUrl = `https://www.instagram.com${pathname.toLowerCase()}`;
                    }
                }
            }
            // ── (D) Google Maps / Google Business ──────────────────────────────
            else if (
                host.includes('maps.google') ||
                host.includes('goo.gl') ||
                host.includes('share.google') ||
                host.includes('maps.app.goo.gl') ||
                (host.includes('google.com') && pathname.includes('/maps'))
            ) {
                const cid = parsed.searchParams.get('cid');
                const placeId = parsed.searchParams.get('placeid') || parsed.searchParams.get('place_id');
                const hexMatch = rawUrl.match(/1s(0x[a-f0-9]+:0x[a-f0-9]+)/i);
                const placeMatch = pathname.match(/\/maps\/place\/([^\/@?]+)/i);
                const searchParam = parsed.searchParams.get('query') || parsed.searchParams.get('q');
                const searchPathMatch = pathname.match(/\/maps\/search\/([^\/?]+)/i);

                if (cid) {
                    normalizedUrl = `google_maps:cid:${cid.trim()}`;
                } else if (placeId) {
                    normalizedUrl = `google_maps:placeid:${placeId.trim()}`;
                } else if (hexMatch && hexMatch[1]) {
                    normalizedUrl = `google_maps:hex:${hexMatch[1].toLowerCase()}`;
                } else if (placeMatch && placeMatch[1]) {
                    const cleanPlace = decodeURIComponent(placeMatch[1]).trim().toLowerCase().replace(/\+/g, ' ');
                    normalizedUrl = `google_maps:place:${cleanPlace}`;
                } else if (searchParam || searchPathMatch) {
                    const rawSearch = searchParam || (searchPathMatch ? searchPathMatch[1] : '');
                    const cleanSearch = decodeURIComponent(rawSearch).trim().toLowerCase().replace(/\+/g, ' ');
                    normalizedUrl = `google_maps:search:${cleanSearch}`;
                } else if (host.includes('goo.gl') || host.includes('share.google') || host.includes('maps.app.goo.gl')) {
                    // Short Google Maps / Business links: preserve host + pathname
                    normalizedUrl = `https://${host}${pathname}`;
                } else {
                    normalizedUrl = `https://${host}${pathname.toLowerCase()}`;
                }
            }
            // ── (E) General Web URLs ──────────────────────────────────────────
            else {
                // Strip common advertising, social, and tracking query params
                [
                    'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
                    'si', 'fbclid', 'igsh', 'feature', 'ref', 'source', 'gclid',
                    'g_st', 'entry', 'g_ep', 'ved', 'referrer'
                ].forEach((p) => parsed.searchParams.delete(p));

                const cleanSearch = parsed.searchParams.toString();
                normalizedUrl = cleanSearch
                    ? `https://${host}${pathname}?${cleanSearch}`
                    : `https://${host}${pathname}`;
            }
        } catch (_) {
            normalizedUrl = rawUrl.toLowerCase().replace(/\/+$/, '');
        }
    }

    if (!pkg && normalizedUrl && normalizedUrl.includes('play.google.com/store/apps/details?id=')) {
        try {
            const u = new URL(normalizedUrl);
            const id = u.searchParams.get('id');
            if (id) pkg = id.toLowerCase().trim();
        } catch (_) {}
    }

    const entityKey = pkg ? `pkg:${pkg}` : (normalizedUrl ? `url:${normalizedUrl}` : undefined);

    return {
        packageId: pkg || undefined,
        normalizedUrl: normalizedUrl || undefined,
        entityKey,
    };
}

function isPrivateOrReservedIp(ip: string): boolean {
    if (net.isIPv4(ip)) {
        const parts = ip.split('.').map(Number);
        if (parts.length !== 4) return true;
        // 0.0.0.0/8 (Current network)
        if (parts[0] === 0) return true;
        // 10.0.0.0/8 (Private)
        if (parts[0] === 10) return true;
        // 127.0.0.0/8 (Loopback)
        if (parts[0] === 127) return true;
        // 169.254.0.0/16 (Link-local / cloud metadata)
        if (parts[0] === 169 && parts[1] === 254) return true;
        // 172.16.0.0/12 (Private)
        if (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) return true;
        // 192.168.0.0/16 (Private)
        if (parts[0] === 192 && parts[1] === 168) return true;
        // 224.0.0.0/4 (Multicast) & 240.0.0.0/4 (Reserved)
        if (parts[0] >= 224) return true;
        return false;
    }
    if (net.isIPv6(ip)) {
        const lower = ip.toLowerCase();
        // ::1 (Loopback) or :: (Unspecified)
        if (lower === '::1' || lower === '::') return true;
        // Unique Local Address fc00::/7
        if (lower.startsWith('fc') || lower.startsWith('fd')) return true;
        // Link-Local fe80::/10
        if (lower.startsWith('fe8') || lower.startsWith('fe9') || lower.startsWith('fea') || lower.startsWith('feb')) return true;
        // IPv4-mapped IPv6 (::ffff:127.0.0.1, etc)
        if (lower.includes('::ffff:')) {
            const v4Part = lower.split('::ffff:')[1];
            if (v4Part && net.isIPv4(v4Part)) return isPrivateOrReservedIp(v4Part);
        }
        return false;
    }
    return true;
}

export async function isSafeTargetHost(hostname: string): Promise<boolean> {
    const cleanHost = hostname.toLowerCase().trim();
    if (
        !cleanHost ||
        cleanHost === 'localhost' ||
        cleanHost.endsWith('.local') ||
        cleanHost.endsWith('.internal') ||
        cleanHost.endsWith('.localhost')
    ) {
        return false;
    }
    if (net.isIP(cleanHost)) {
        return !isPrivateOrReservedIp(cleanHost);
    }
    try {
        const lookupRes = await dns.promises.lookup(cleanHost, { all: true });
        if (!lookupRes || lookupRes.length === 0) return false;
        for (const entry of lookupRes) {
            if (isPrivateOrReservedIp(entry.address)) {
                return false;
            }
        }
        return true;
    } catch (_) {
        return false;
    }
}

/**
 * Asynchronously follows redirects for Google Maps short links (e.g. maps.app.goo.gl, goo.gl/maps)
 * and generic short links to retrieve the full canonical destination URL before extracting place/cid/search identity.
 * Features strict SSRF protection against loopback, private RFC1918 IPs, and cloud metadata addresses.
 */
export async function resolveShortUrl(url: string, timeoutMs = 4000): Promise<string> {
    if (!url || typeof url !== 'string') return url || '';
    const cleanUrl = url.trim();
    const lower = cleanUrl.toLowerCase();

    if (
        !lower.includes('maps.app.goo.gl') &&
        !lower.includes('goo.gl/maps') &&
        !lower.includes('goo.gl') &&
        !lower.includes('bit.ly') &&
        !lower.includes('tinyurl.com') &&
        !lower.includes('t.co') &&
        !lower.includes('cutt.ly')
    ) {
        return cleanUrl;
    }

    if (resolvedUrlCache.has(lower)) {
        return resolvedUrlCache.get(lower)!;
    }

    let currentUrl = cleanUrl.startsWith('http') ? cleanUrl : `https://${cleanUrl}`;

    try {
        let redirectCount = 0;
        const maxRedirects = 5;

        while (redirectCount < maxRedirects) {
            const parsed = new URL(currentUrl);
            if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
                return cleanUrl; // SSRF safety: reject non-http protocols
            }

            const isSafe = await isSafeTargetHost(parsed.hostname);
            if (!isSafe) {
                // SSRF protection: reject private/local target host
                return cleanUrl;
            }

            const controller = new AbortController();
            const timer = setTimeout(() => controller.abort(), timeoutMs);

            let res: any;
            try {
                res = await fetch(currentUrl, {
                    method: 'HEAD',
                    redirect: 'manual', // Strictly manual redirect following to inspect each hop
                    signal: controller.signal,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    },
                });
            } finally {
                clearTimeout(timer);
            }

            if ([301, 302, 303, 307, 308].includes(res.status)) {
                const location = res.headers.get('location');
                if (!location) break;

                const nextUrl = new URL(location, currentUrl).toString();
                if (nextUrl === currentUrl) break;
                currentUrl = nextUrl;
                redirectCount++;
            } else {
                break;
            }
        }

        if (currentUrl && currentUrl !== cleanUrl) {
            cacheResolvedUrl(cleanUrl, currentUrl);
            return currentUrl;
        }
    } catch (_) {
        // Fallback safely to original URL on network/abort error
    }

    return cleanUrl;
}

