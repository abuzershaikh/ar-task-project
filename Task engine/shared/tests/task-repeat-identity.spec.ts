import { cacheResolvedUrl, canonicalizeGoogleBusinessTarget, extractTaskIdentity, resolvedUrlCache } from '../common/utils/task-identity.util';
import { eligibleTaskPushTokens, resolveEligibleTaskPushTokens } from '../common/utils/task-push-tokens.util';
import { TaskQueryService } from '../../task-engine/queries/task-query.service';
import { TaskCommandService } from '../../task-engine/handlers/task-command.service';
import { TaskRepository } from '../database/repositories/task.repository';
import { UserRepository } from '../database/repositories/user.repository';
import { NotificationEngineService } from '../../notification-engine/notification.service';

const canonical = 'https://www.google.com/search?kgmid=/g/11y99b1w5d&q=A2M+INFOTECH+PRIVATE+LIMITED';
const short = 'https://share.google/WkRHZB34ySWejYpCl';
const past: any = { id: 'old-task', orderId: 'buyer-1-order', campaignId: 'buyer-1-order', assignedTo: 'user-1',
    requirements: { targetUrl: short, canonicalUrl: canonical, businessName: 'A2m Infotech Pvt Ltd' } };
const next: any = { id: 'new-task', orderId: 'buyer-2-order', campaignId: 'buyer-2-order',
    requirements: { targetUrl: canonical, businessName: 'A2M INFOTECH PRIVATE LIMITED' } };
const token = 'synthetic-fcm-device-token-123456789';

describe('Cross-buyer task identity and push exclusion', () => {
    beforeEach(() => resolvedUrlCache.clear());

    it('matches a persisted old short link after a cold restart despite different business names', () => {
        const oldIdentity = extractTaskIdentity(past);
        const newIdentity = extractTaskIdentity(next);
        expect(oldIdentity.entityKeys.some((key) => newIdentity.entityKeys.includes(key))).toBe(true);
        expect(oldIdentity.entityKey).toBe('google_maps:kgmid:/g/11y99b1w5d');
    });

    it('canonicalizes a link and remains correct after clearing the resolver cache', async () => {
        cacheResolvedUrl(short, canonical);
        const requirements = await canonicalizeGoogleBusinessTarget({ targetUrl: short });
        resolvedUrlCache.clear();
        expect(requirements.originalTargetUrl).toBe(short);
        expect(extractTaskIdentity({ requirements }).normalizedUrl).toBe('google_maps:kgmid:/g/11y99b1w5d');
    });

    it('rejects a Google Business URL without a verifiable listing ID', async () => {
        await expect(canonicalizeGoogleBusinessTarget({ targetUrl: 'https://www.google.com/maps/search/Test+Name' })).rejects.toThrow('listing ID');
    });

    it('matches Google Maps hex and decimal CID forms independently of business names', () => {
        const hex = extractTaskIdentity({ targetUrl: 'https://www.google.com/maps/place/Test/data=!1s0x123:0xabcdef' });
        const cid = extractTaskIdentity({ targetUrl: `https://maps.google.com/?cid=${BigInt('0xabcdef')}` });
        expect(hex.entityKey).toBe(cid.entityKey);
    });

    it('supports the official query_place_id link format', () => {
        expect(extractTaskIdentity({ targetUrl: 'https://www.google.com/maps/search/?api=1&query=Test&query_place_id=ChIJExample' }).entityKeys)
            .toContain('google_maps:placeid:chijexample');
    });

    it('recognizes a percent-encoded ftid as the same decimal CID', () => {
        const identity = extractTaskIdentity({ targetUrl: 'https://www.google.com/maps?q=Business&ftid=0x123%3A0xabcdef' });
        expect(identity.entityKeys).toContain(`google_maps:cid:${BigInt('0xabcdef')}`);
    });

    it('matches market:// Play Store links to the HTTPS package identity', () => {
        const market = extractTaskIdentity({ targetUrl: 'market://details?id=com.example.app' });
        const https = extractTaskIdentity({ targetUrl: 'https://play.google.com/store/apps/details?id=com.example.app&hl=en' });
        expect(market.packageId).toBe(https.packageId);
        expect(market.entityKey).toBe('pkg:com.example.app');
    });

    it('hides a new buyer order based on the old canonical business identity', async () => {
        const repo: any = {
            findAvailableForAssignment: async () => [next],
            query: async () => [], findByWorker: async () => [past], findByIds: async () => [],
        };
        const service = new TaskQueryService(repo,
            { findCampaignIdsByWorker: async () => [] } as any,
            { findByWorker: async () => [] } as any,
            { findByWorker: async () => [] } as any,
            { findById: async () => ({ email: 'worker@example.test' }) } as any);
        expect(await service.getAvailableTasks('user-1', 'worker@example.test')).toEqual([]);
    });

    it('blocks the accept duplicate guard using old canonical history', async () => {
        const command: any = Object.create(TaskCommandService.prototype);
        const manager = { query: async () => [], find: async (entity: any) => entity.name === 'Task' ? [past] : [] };
        await expect(command.verifyNoDuplicateAppOrUrlTransactional(manager, next, ['user-1'], extractTaskIdentity(next)))
            .rejects.toThrow('already completed');
    });

    it('rejects acceptance of an unverified Google Maps task', async () => {
        const command: any = Object.create(TaskCommandService.prototype);
        const bad = { requirements: { platform: 'google_business', targetUrl: 'https://www.google.com/maps/search/Unverified' } };
        await expect(command.verifyNoDuplicateAppOrUrlTransactional({}, bad, ['user-1'], extractTaskIdentity(bad)))
            .rejects.toThrow('could not be verified');
    });

    it('does not offer tasks when any required history source is unavailable', async () => {
        const repo: any = { findAvailableForAssignment: async () => [next], query: async () => { throw new Error('DB down'); } };
        const service = new TaskQueryService(repo, {} as any, {} as any, {} as any, {} as any);
        await expect(service.getAvailableTasks('user-1')).rejects.toThrow('could not be verified');
    });

    it('does not ignore a failed durable identity lookup when filtering push recipients', async () => {
        const repo = new TaskRepository({ query: async () => { throw new Error('ledger down'); } } as any);
        await expect(repo.findWorkerIdsWithPackageOrUrl('com.example.app')).rejects.toThrow('ledger down');
    });

    it('suppresses a shared device if one of its legacy owners already did the task', () => {
        const users = [
            { id: 'completed', metadata: { fcmToken: token } },
            { id: 'another-login', metadata: { deviceToken: token } },
            { id: 'fresh', metadata: { fcmToken: token + '-fresh' } },
        ];
        expect(eligibleTaskPushTokens(users, new Set(['completed']))).toEqual([token + '-fresh']);
    });

    it('sends at most one push to each eligible token, including both metadata aliases', () => {
        expect(eligibleTaskPushTokens([
            { id: 'a', metadata: { fcmToken: token, deviceToken: token } },
            { id: 'b', metadata: { fcmToken: token } },
        ], new Set())).toEqual([token]);
    });

    it.each(['exclusion', 'workers'])('suppresses push when the %s lookup fails', async (source) => {
        const failed = async () => { throw new Error('DB down'); };
        const result = await resolveEligibleTaskPushTokens(extractTaskIdentity(next),
            source === 'exclusion' ? failed : async () => [],
            source === 'workers' ? failed : async () => [{ id: 'user-1', metadata: { fcmToken: token } }],
            jest.fn());
        expect(result).toEqual([]);
    });

    it('never falls back to broadcast when the task identity is missing', async () => {
        const load = jest.fn();
        expect(await resolveEligibleTaskPushTokens({ entityKeys: [] }, load, load, jest.fn())).toEqual([]);
        expect(load).not.toHaveBeenCalled();
    });

    it('suppresses Google Business push if the listing has no stable ID', async () => {
        const identity = extractTaskIdentity({ requirements: { platform: 'google_business', targetUrl: 'https://www.google.com/maps/search/Unverified' } });
        const load = jest.fn();
        expect(await resolveEligibleTaskPushTokens(identity, load, load, jest.fn())).toEqual([]);
        expect(load).not.toHaveBeenCalled();
    });

    it('does not resurrect a stale device token from an old worker Firestore profile', async () => {
        const service: any = Object.create(NotificationEngineService.prototype);
        service.firebaseAdmin = { getFirestoreUser: jest.fn() };
        expect(await service.resolveFcmToken({ id: 'old-worker', role: 'WORKER', metadata: {} }, 'old-worker')).toBeNull();
        expect(service.firebaseAdmin.getFirestoreUser).not.toHaveBeenCalled();
    });

    it('commits a token transfer before releasing its device lock and preserves other metadata', async () => {
        const calls: string[] = [];
        const runner: any = { isTransactionActive: false,
            connect: async () => {}, release: async () => { calls.push('release'); },
            query: jest.fn(async (sql) => {
                calls.push(sql);
                if (sql.includes('GET_LOCK')) return [{ acquired: 1 }];
                if (sql.startsWith('SELECT id FROM users')) return [{ id: 'user-1' }];
                return [];
            }),
            startTransaction: async () => { runner.isTransactionActive = true; },
            commitTransaction: async () => { calls.push('commit'); runner.isTransactionActive = false; },
            rollbackTransaction: async () => { calls.push('rollback'); },
        };
        const repo = new UserRepository({ manager: { connection: { createQueryRunner: () => runner } } } as any);
        await repo.claimWorkerDeviceToken('user-1', token);
        expect(calls.findIndex((sql) => sql.includes('RELEASE_LOCK'))).toBeGreaterThan(calls.indexOf('commit'));
        expect(calls.some((sql) => sql.includes('JSON_REMOVE') && sql.includes("role = 'WORKER'"))).toBe(true);
        expect(calls.some((sql) => sql.includes('JSON_SET(COALESCE'))).toBe(true);
    });
});
