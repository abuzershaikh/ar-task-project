export interface TaskIdentity {
    packageId?: string;
    normalizedUrl?: string;
    entityKey?: string;
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
                if (cid) {
                    normalizedUrl = `google_maps:cid:${cid.trim()}`;
                } else if (placeId) {
                    normalizedUrl = `google_maps:placeid:${placeId.trim()}`;
                } else if (host.includes('goo.gl') || host.includes('share.google') || host.includes('maps.app.goo.gl')) {
                    // Short Google Maps / Business links: preserve path, strip tracking params
                    normalizedUrl = `https://${host}${pathname}`;
                } else {
                    // Clean Google Maps path, strip all query tracking
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
