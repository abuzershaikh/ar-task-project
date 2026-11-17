import { hasStableGoogleBusinessIdentity, TaskIdentity } from './task-identity.util';

/** A legacy token shared by an excluded account must not leak the task to that device. */
export function eligibleTaskPushTokens(users: any[], excludedIds: Set<string>): string[] {
    const eligible = new Set<string>();
    const blocked = new Set<string>();
    for (const user of users) {
        const metadata = typeof user.metadata === 'string' ? JSON.parse(user.metadata) : user.metadata || {};
        const tokens = [...new Set([metadata.fcmToken, metadata.deviceToken])]
            .filter((token): token is string => typeof token === 'string' && token.length > 20);
        const excluded = [user.id, user.email].filter(Boolean)
            .some((id) => excludedIds.has(id.toLowerCase().trim()));
        for (const token of tokens) (excluded ? blocked : eligible).add(token);
    }
    return [...eligible].filter((token) => !blocked.has(token));
}

export async function resolveEligibleTaskPushTokens(
    identity: TaskIdentity,
    loadExcludedIds: () => Promise<string[]>,
    loadWorkers: () => Promise<any[]>,
    onError: (error: any) => void,
): Promise<string[]> {
    if (!identity.entityKeys.length || (identity.googleBusiness && !hasStableGoogleBusinessIdentity(identity))) return [];
    try {
        const excluded = new Set((await loadExcludedIds()).map((id) => id.toLowerCase().trim()));
        return eligibleTaskPushTokens(await loadWorkers(), excluded);
    } catch (error) {
        onError(error);
        return []; // Explicit empty recipients; never undefined/topic fallback.
    }
}
