import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tutorial } from '../entities/tutorial.entity';

export interface TutorialFilterOptions {
    targetAudience?: string; // 'buyer', 'worker', 'all'
    category?: string;
    search?: string;
    isActive?: boolean;
}

@Injectable()
export class TutorialRepository {
    constructor(
        @InjectRepository(Tutorial)
        private readonly repo: Repository<Tutorial>,
    ) { }

    async findAll(options: TutorialFilterOptions = {}): Promise<Tutorial[]> {
        const query = this.repo.createQueryBuilder('tutorial');

        if (options.targetAudience && options.targetAudience !== 'all') {
            query.andWhere(
                '(tutorial.targetAudience = :audience OR tutorial.targetAudience = :allAudience)',
                { audience: options.targetAudience, allAudience: 'all' },
            );
        }

        if (options.category && options.category !== 'All' && options.category.trim() !== '') {
            query.andWhere('LOWER(tutorial.category) = LOWER(:category)', { category: options.category.trim() });
        }

        if (options.search && options.search.trim() !== '') {
            const term = `%${options.search.trim().toLowerCase()}%`;
            query.andWhere(
                '(LOWER(tutorial.title) LIKE :term OR LOWER(tutorial.tags) LIKE :term OR LOWER(tutorial.category) LIKE :term OR LOWER(tutorial.description) LIKE :term)',
                { term },
            );
        }

        if (options.isActive !== undefined) {
            query.andWhere('tutorial.isActive = :isActive', { isActive: options.isActive });
        }

        query.orderBy('tutorial.displayOrder', 'ASC')
            .addOrderBy('tutorial.createdAt', 'DESC');

        return query.getMany();
    }

    async findCategories(targetAudience?: string): Promise<string[]> {
        const query = this.repo.createQueryBuilder('tutorial')
            .select('DISTINCT tutorial.category', 'category')
            .where('tutorial.isActive = :isActive', { isActive: true });

        if (targetAudience && targetAudience !== 'all') {
            query.andWhere(
                '(tutorial.targetAudience = :audience OR tutorial.targetAudience = :allAudience)',
                { audience: targetAudience, allAudience: 'all' },
            );
        }

        const raw = await query.getRawMany();
        const categories = raw.map(r => r.category).filter(Boolean);
        return categories;
    }

    async findById(id: string): Promise<Tutorial | null> {
        return this.repo.findOne({ where: { id } });
    }

    async create(data: Partial<Tutorial>): Promise<Tutorial> {
        const tutorial = this.repo.create(data);
        return this.repo.save(tutorial);
    }

    async update(id: string, data: Partial<Tutorial>): Promise<Tutorial | null> {
        await this.repo.update(id, data);
        return this.findById(id);
    }

    async delete(id: string): Promise<boolean> {
        const res = await this.repo.delete(id);
        return (res.affected || 0) > 0;
    }

    async incrementViews(id: string): Promise<void> {
        await this.repo.createQueryBuilder()
            .update(Tutorial)
            .set({ viewsCount: () => 'views_count + 1' })
            .where('id = :id', { id })
            .execute();
    }
}
