import * as dns from 'dns';
import * as net from 'net';

export interface TaskIdentity {
    packageId?: string;
    normalizedUrl?: string;
    businessNameKey?: string;
    entityKey?: string;
    entityKeys: string[];
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
 * Universal extractor and normalizer for Task Identity (Package ID, Target URL, Business Name).
 * Used across TaskQueryService, TaskCommandService, MatchingEngine, and NotificationEngine
 * to enforce the strict business rule:
 * "App Reviews & Google Reviews ke Task mei Repeat Users Task karrahe hai Usme Unique System Chahiye,
 * same link / same app / same Google review aane par repeat user ko task nahi jana chahiye."
 */
export function extractTaskIdentity(task: any): TaskIdentity {
    if (!task) return { entityKeys: [] };

    const reqs = task.requirements || {};
    const meta = task.metadata || {};
    const entityKeys: string[] = [];

    // ── 1. Resolve Package ID (Play Store / App Install) ──────────────────────
    let rawPkg = (
        reqs.packageId ||
        meta.packageId ||
        reqs.appPackage ||
        reqs.packageName ||
        meta.appPackage ||
        meta.packageName ||
        task.packageId ||
        ''
    ).toString().trim().toLowerCase();

    // Reset falsy or invalid package values
    if (rawPkg === 'null' || rawPkg === 'undefined' || rawPkg === '[object object]') {
        rawPkg = '';
    }

    // If packageId was accidentally passed as a URL or query string, extract id param
    if (rawPkg.includes('id=')) {
        const match = rawPkg.match(/[?&]id=([a-zA-Z0-9_.]+)/i);
        if (match && match[1]) rawPkg = match[1].toLowerCase().trim();
    } else if (rawPkg.includes('/')) {
        const parts = rawPkg.split('/').filter(Boolean);
        const lastPart = parts[parts.length - 1];
        if (lastPart && /^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$/.test(lastPart)) {
            rawPkg = lastPart.toLowerCase().trim();
        } else {
            rawPkg = '';
        }
    }

    let pkg = rawPkg;

    // ── 2. Resolve Raw Target URL ─────────────────────────────────────────────
    let rawUrl = (
        reqs.canonicalUrl ||
        reqs.canonicalTargetUrl ||
        meta.canonicalUrl ||
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
    let businessNameKey: string | undefined = undefined;

    // ── 3. Resolve Business Name for Google Business / Maps tasks ─────────────
    const rawBusinessName = (
        reqs.businessName ||
        meta.businessName ||
        reqs.appName ||
        meta.appName ||
        task.businessName ||
        ''
    ).toString().trim();

    if (rawBusinessName && rawBusinessName !== 'null' && rawBusinessName !== 'undefined') {
        const cleanName = rawBusinessName
            .replace(/\s*-\s*Google Maps.*/i, '')
            .replace(/\s*·\s*Google Maps.*/i, '')
            .replace(/\s*\|\s*Google Maps.*/i, '')
            .replace(/Google Maps/i, '')
            .replace(/Google Search/i, '')
            .replace(/Dynamic Link Not Found/i, '')
            .replace(/Dynamic Link/i, '')
            .trim();

        const normName = cleanName.toLowerCase().replace(/[^a-z0-9]/g, '');
        if (normName.length >= 3 && !['google', 'search', 'googlemaps', 'googlesearch', 'dynamiclink', 'notfound'].includes(normName)) {
            businessNameKey = `gmb:name:${normName}`;
            entityKeys.push(businessNameKey);
        }
    }

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
                    pkg = idParam;
                    normalizedUrl = `https://play.google.com/store/apps/details?id=${idParam}`;
                }
            } else if (rawUrl.startsWith('market://')) {
                const match = rawUrl.match(/id=([a-zA-Z0-9_.]+)/i);
                if (match && match[1]) {
                    const idParam = match[1].toLowerCase().trim();
                    pkg = idParam;
                    normalizedUrl = `https://play.google.com/store/apps/details?id=${idParam}`;
                }
            } else if (/^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$/.test(rawUrl)) {
                pkg = rawUrl.toLowerCase().trim();
                normalizedUrl = `https://play.google.com/store/apps/details?id=${pkg}`;
            }
            // ── (B) YouTube Links (Watch, Short, Shorts, Embed, Live, Channel) ───
            else if (host.includes('youtube.com') || host.includes('youtu.be')) {
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
                const igCodeMatch = pathname.match(/\/(?:p|reel|reels)\/([A-Za-z0-9_-]+)/i);
                if (igCodeMatch && igCodeMatch[1]) {
                    const shortcode = igCodeMatch[1].trim();
                    normalizedUrl = `https://www.instagram.com/p/${shortcode}`;
                } else {
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
                host.includes('g.page') ||
                host.includes('g.co') ||
                (host.includes('google.') && (
                    pathname.includes('/maps') ||
                    pathname.includes('/local') ||
                    (pathname.includes('/search') && (parsed.searchParams.has('kgmid') || parsed.searchParams.has('q') || parsed.searchParams.has('lrd')))
                ))
            ) {
                const cid = parsed.searchParams.get('cid');
                const placeId = parsed.searchParams.get('placeid') || parsed.searchParams.get('place_id');
                let rawKgmid = parsed.searchParams.get('kgmid');
                if (rawKgmid) {
                    try { rawKgmid = decodeURIComponent(rawKgmid); } catch (_) {}
                }
                const hexMatch = rawUrl.match(/1s(0x[a-f0-9]+:0x[a-f0-9]+)/i);
                const placeMatch = pathname.match(/\/maps\/place\/([^\/@?]+)/i);
                const searchParam = parsed.searchParams.get('query') || parsed.searchParams.get('q');
                const searchPathMatch = pathname.match(/\/maps\/search\/([^\/?]+)/i);

                if (rawKgmid) {
                    const cleanKgmid = rawKgmid.toLowerCase().trim();
                    normalizedUrl = `google_maps:kgmid:${cleanKgmid}`;
                    entityKeys.push(`url:google_maps:kgmid:${cleanKgmid}`);
                    entityKeys.push(`google_maps:kgmid:${cleanKgmid}`);
                }
                if (cid) {
                    const cleanCid = cid.trim();
                    if (!normalizedUrl) normalizedUrl = `google_maps:cid:${cleanCid}`;
                    entityKeys.push(`url:google_maps:cid:${cleanCid}`);
                    entityKeys.push(`google_maps:cid:${cleanCid}`);
                }
                if (placeId) {
                    const cleanPid = placeId.trim();
                    if (!normalizedUrl) normalizedUrl = `google_maps:placeid:${cleanPid}`;
                    entityKeys.push(`url:google_maps:placeid:${cleanPid}`);
                    entityKeys.push(`google_maps:placeid:${cleanPid}`);
                }
                if (hexMatch && hexMatch[1]) {
                    const cleanHex = hexMatch[1].toLowerCase();
                    if (!normalizedUrl) normalizedUrl = `google_maps:hex:${cleanHex}`;
                    entityKeys.push(`url:google_maps:hex:${cleanHex}`);
                    entityKeys.push(`google_maps:hex:${cleanHex}`);
                }
                if (placeMatch && placeMatch[1]) {
                    const cleanPlace = decodeURIComponent(placeMatch[1]).trim().toLowerCase().replace(/\+/g, ' ');
                    if (!normalizedUrl) normalizedUrl = `google_maps:place:${cleanPlace}`;
                    entityKeys.push(`url:google_maps:place:${cleanPlace}`);
                    const placeAlnum = cleanPlace.split(',')[0].replace(/[^a-z0-9]/g, '');
                    if (placeAlnum.length >= 3) {
                        entityKeys.push(`gmb:name:${placeAlnum}`);
                        if (!businessNameKey) businessNameKey = `gmb:name:${placeAlnum}`;
                    }
                }
                if (searchParam || searchPathMatch) {
                    const rawSearch = searchParam || (searchPathMatch ? searchPathMatch[1] : '');
                    const cleanSearch = decodeURIComponent(rawSearch).trim().toLowerCase().replace(/\+/g, ' ');
                    if (!normalizedUrl) normalizedUrl = `google_maps:search:${cleanSearch}`;
                    entityKeys.push(`url:google_maps:search:${cleanSearch}`);
                    const searchAlnum = cleanSearch.split(',')[0].replace(/[^a-z0-9]/g, '');
                    if (searchAlnum.length >= 3 && !['google', 'maps', 'search'].includes(searchAlnum)) {
                        entityKeys.push(`gmb:name:${searchAlnum}`);
                        if (!businessNameKey) businessNameKey = `gmb:name:${searchAlnum}`;
                    }
                }

                if (!normalizedUrl) {
                    if (host.includes('goo.gl') || host.includes('share.google') || host.includes('maps.app.goo.gl') || host.includes('g.page') || host.includes('g.co')) {
                        normalizedUrl = `https://${host}${pathname}`;
                    } else {
                        normalizedUrl = `https://${host}${pathname.toLowerCase()}`;
                    }
                }
            }
            // ── (E) General Web URLs ──────────────────────────────────────────
            else {
                [
                    'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
                    'si', 'fbclid', 'igsh', 'feature', 'ref', 'source', 'gclid',
                    'g_st', 'entry', 'g_ep', 'ved', 'referrer', 'shem', 'shndl', 'kgs'
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

    // ── 4. Fallback Package ID extraction from resolved normalized URL ────────
    if (!pkg && normalizedUrl && normalizedUrl.includes('play.google.com/store/apps/details?id=')) {
        try {
            const u = new URL(normalizedUrl);
            const id = u.searchParams.get('id');
            if (id) pkg = id.toLowerCase().trim();
        } catch (_) {}
    }

    // ── 5. Populate All Entity Keys for Multi-Dimensional Deduplication ───────
    if (pkg) {
        pkg = pkg.toLowerCase().trim();
        entityKeys.push(`pkg:${pkg}`);
        entityKeys.push(`app:${pkg}`);
        entityKeys.push(`https://play.google.com/store/apps/details?id=${pkg}`);
        entityKeys.push(`url:https://play.google.com/store/apps/details?id=${pkg}`);
    }

    if (normalizedUrl) {
        entityKeys.push(`url:${normalizedUrl}`);
        entityKeys.push(normalizedUrl);
    }

    // Deduplicate and sanitize entityKeys
    const dedupedKeys = Array.from(
        new Set(
            entityKeys
                .map((k) => (k || '').toString().toLowerCase().trim())
                .filter((k) => k.length > 0 && k !== 'pkg:null' && k !== 'pkg:undefined' && k !== 'app:null')
        )
    );

    const primaryEntityKey = pkg ? `pkg:${pkg}` : (dedupedKeys[0] || (normalizedUrl ? `url:${normalizedUrl}` : undefined));

    return {
        packageId: pkg || undefined,
        normalizedUrl: normalizedUrl || undefined,
        businessNameKey,
        entityKey: primaryEntityKey,
        entityKeys: dedupedKeys,
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
        !lower.includes('share.google') &&
        !lower.includes('g.page') &&
        !lower.includes('g.co') &&
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
        const maxRedirects = 8;

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
                // Use GET with Range/small payload if host is Google (Google services only return 301 on GET)
                const method = (parsed.hostname.includes('google') || parsed.hostname === 'share.google') ? 'GET' : 'HEAD';
                res = await fetch(currentUrl, {
                    method,
                    redirect: 'manual', // Strictly manual redirect following to inspect each hop
                    signal: controller.signal,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
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
            currentUrl = sanitizeGoogleMapsUrl(currentUrl);
            cacheResolvedUrl(cleanUrl, currentUrl);
            return currentUrl;
        }
    } catch (_) {
        // Fallback safely to original URL on network/abort error
    }

    return cleanUrl;
}

/**
 * Remove tracking noise (utm_*, g_st, entry, coh, skid, etc.) from Google Maps URLs
 * while preserving place paths, coordinates, and data parameters.
 */
export function sanitizeGoogleMapsUrl(url: string): string {
    if (!url || typeof url !== 'string') return url || '';
    const clean = url.trim();
    if (!clean.includes('google.com/maps') && !clean.includes('maps.google') && !clean.includes('/maps/place/')) {
        return clean;
    }
    try {
        const u = new URL(clean);
        [
            'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content',
            'entry', 'coh', 'g_ep', 'skid', 'g_st', 'ved', 'source', 'ref', 'feature'
        ].forEach((p) => u.searchParams.delete(p));
        return u.toString();
    } catch (_) {
        return clean;
    }
}

