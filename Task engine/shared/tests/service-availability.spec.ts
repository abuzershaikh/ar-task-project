import { ServiceCatalogService } from '../modules/service-catalog/services/service-catalog.service';
import { AdminServiceCatalogController } from '../../apps/api/controllers/admin/service-catalog.controller';
import { PricingEngine } from '../engines/pricing-engine/pricing.engine';

describe('Service availability', () => {
    let repo: any;
    let service: ServiceCatalogService;
    beforeEach(() => {
        repo = {
            findById: jest.fn().mockResolvedValue({ id: 'maps', isActive: true }),
            update: jest.fn().mockImplementation(async (id, data) => ({ id, ...data })),
        };
        service = new ServiceCatalogService(repo);
    });

    it.each([true, false])('persists explicit status %s and returns confirmed state', async (isActive) => {
        const controller = new AdminServiceCatalogController(service, null as any, null as any);
        expect(await controller.setServiceStatus('maps', { isActive })).toEqual({
            success: true, service: { id: 'maps', isActive },
        });
        expect(repo.update).toHaveBeenCalledWith('maps', { isActive });
    });

    it.each([undefined, null, 'false', 0, 1])('rejects invalid status %s without updating', async (isActive) => {
        await expect(service.updateService('maps', { isActive } as any)).rejects.toThrow('must be a boolean');
        expect(repo.update).not.toHaveBeenCalled();
    });

    it('does not reactivate a deleted service', async () => {
        repo.findById.mockResolvedValue({ id: 'maps', deletedAt: new Date() });
        await expect(service.updateService('maps', { isActive: true })).rejects.toThrow('not found');
        expect(repo.update).not.toHaveBeenCalled();
    });

    it('rejects stale buyer orders for an inactive service before pricing or charging', async () => {
        repo.findById.mockResolvedValue({ id: 'maps', name: 'Maps Only Rating', isActive: false });
        const pricing = { getActivePricingVersion: jest.fn() };
        const engine = new PricingEngine(repo, pricing as any, null as any, null as any, null as any, null as any);
        await expect(engine.createOrderPriceSnapshot('maps', 10)).rejects.toThrow('inactive');
        expect(pricing.getActivePricingVersion).not.toHaveBeenCalled();
    });
});
