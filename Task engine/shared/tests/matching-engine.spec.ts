import { LocationFilterService } from '../../matching-engine/filters/location-filter.service';
import { CategoryFilterService } from '../../matching-engine/filters/category-filter.service';
import { CapacityFilterService } from '../../matching-engine/filters/capacity-filter.service';
import { RankingCalculator } from '../../ranking-engine/calculators/ranking-calculator';
import { EligibilityEngineService } from '../../eligibility-engine/eligibility.service';

describe('Matching Engine Hardened Tests', () => {
    describe('1. Location Filter Edge Cases (Undefined State & Case Insensitivity)', () => {
        let locationFilter: LocationFilterService;

        beforeEach(() => {
            locationFilter = new LocationFilterService({} as any);
        });

        it('should NOT match when required location state is undefined and worker state is undefined if city is required', async () => {
            const context: any = {
                requirements: {
                    location: { city: 'Mumbai', state: undefined, country: undefined },
                },
            };

            const loadedWorkers = [
                { id: 'W1', profile: { location: { city: 'Delhi', state: undefined, country: undefined } } },
                { id: 'W2', profile: { location: { city: 'Mumbai', state: 'MH', country: 'IN' } } },
            ];

            const result = await locationFilter.apply(['W1', 'W2'], context, loadedWorkers);
            expect(result).toEqual(['W2']);
        });

        it('should match city case-insensitively', async () => {
            const context: any = {
                requirements: {
                    location: { city: 'mumbai' },
                },
            };

            const loadedWorkers = [
                { id: 'W1', profile: { location: { city: 'MUMBAI' } } },
                { id: 'W2', profile: { location: { city: 'Pune' } } },
            ];

            const result = await locationFilter.apply(['W1', 'W2'], context, loadedWorkers);
            expect(result).toEqual(['W1']);
        });
    });

    describe('2. Category Filter Edge Cases (Case-Insensitive & Trimmed)', () => {
        let categoryFilter: CategoryFilterService;

        beforeEach(() => {
            categoryFilter = new CategoryFilterService({} as any);
        });

        it('should match category regardless of case and surrounding whitespace', async () => {
            const context: any = {
                requirements: {
                    category: ' Delivery ',
                },
            };

            const loadedWorkers = [
                { id: 'W1', profile: { categories: ['delivery', 'survey'] } },
                { id: 'W2', profile: { categories: ['Plumbing'] } },
            ];

            const result = await categoryFilter.apply(['W1', 'W2'], context, loadedWorkers);
            expect(result).toEqual(['W1']);
        });
    });

    describe('3. Capacity Filter Bulk Check', () => {
        it('should filter out workers who reached max concurrent task limit (5)', async () => {
            const mockTaskRepo: any = {
                getWorkerActiveTaskCounts: jest.fn().mockResolvedValue(
                    new Map([
                        ['W1', 5], // Full
                        ['W2', 2], // Eligible
                        ['W3', 0], // Eligible
                    ]),
                ),
            };

            const capacityFilter = new CapacityFilterService(mockTaskRepo);
            const result = await capacityFilter.apply(['W1', 'W2', 'W3'], {} as any);

            expect(result).toEqual(['W2', 'W3']);
            expect(mockTaskRepo.getWorkerActiveTaskCounts).toHaveBeenCalledWith(['W1', 'W2', 'W3']);
        });
    });

    describe('4. Deterministic Ranking Tie-Breaker', () => {
        let rankingCalculator: RankingCalculator;

        beforeEach(() => {
            rankingCalculator = new RankingCalculator({} as any);
        });

        it('should sort by score DESC, and use workerId ASC as a deterministic tie-breaker when scores are equal', async () => {
            const workerIds = ['W-CHARLIE', 'W-ALPHA', 'W-BRAVO'];
            const scoresMap = new Map([
                ['W-CHARLIE', 85],
                ['W-ALPHA', 85],
                ['W-BRAVO', 90],
            ]);

            const ranked = await rankingCalculator.rank(workerIds, 'TASK-1', scoresMap);

            expect(ranked[0].workerId).toBe('W-BRAVO'); // Score 90
            expect(ranked[1].workerId).toBe('W-ALPHA'); // Score 85 (tie-breaker alpha)
            expect(ranked[2].workerId).toBe('W-CHARLIE'); // Score 85 (tie-breaker charlie)
        });
    });

    describe('5. Fail-Closed Eligibility Engine Check', () => {
        let eligibilityEngine: EligibilityEngineService;

        beforeEach(() => {
            eligibilityEngine = new EligibilityEngineService();
        });

        it('should return isEligible: false for invalid worker IDs or throwing errors', async () => {
            const result = await eligibilityEngine.checkEligibility('', 'TASK-1');
            expect(result.isEligible).toBe(false);
            expect(result.reasons).toContain('Invalid worker ID');
        });

        it('should evaluate batch check with fail-closed map output', async () => {
            const map = await eligibilityEngine.batchCheckEligibility(['W1', 'W2'], 'TASK-1');
            expect(map.get('W1')?.isEligible).toBe(true);
            expect(map.get('W3')?.isEligible).toBeUndefined(); // Missing entry is undefined, evaluated fail-closed as false in CandidateService
        });
    });
});
