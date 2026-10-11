import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { TutorialRepository, TutorialFilterOptions } from '../../shared/database/repositories/tutorial.repository';
import { Tutorial } from '../../shared/database/entities/tutorial.entity';
import { YouTubeMetadataService } from '../../shared/services/youtube-metadata.service';

export interface CreateTutorialDto {
    title: string;
    description?: string;
    videoUrl: string;
    thumbnailUrl?: string;
    category?: string;
    tags?: string;
    targetAudience?: string; // 'buyer', 'worker', 'all'
    displayOrder?: number;
    duration?: string;
    isActive?: boolean;
}

export interface UpdateTutorialDto {
    title?: string;
    description?: string;
    videoUrl?: string;
    thumbnailUrl?: string;
    category?: string;
    tags?: string;
    targetAudience?: string;
    displayOrder?: number;
    duration?: string;
    isActive?: boolean;
}

@Injectable()
export class TutorialService {
    private readonly logger = new Logger(TutorialService.name);

    constructor(
        private readonly tutorialRepo: TutorialRepository,
        private readonly youtubeMetadataService: YouTubeMetadataService,
    ) { }

    async listTutorials(options: TutorialFilterOptions): Promise<Tutorial[]> {
        return this.tutorialRepo.findAll(options);
    }

    async getCategories(targetAudience?: string): Promise<string[]> {
        return this.tutorialRepo.findCategories(targetAudience);
    }

    async getTutorialById(id: string): Promise<Tutorial> {
        const item = await this.tutorialRepo.findById(id);
        if (!item) {
            throw new NotFoundException(`Tutorial with ID ${id} not found`);
        }
        return item;
    }

    async createTutorial(dto: CreateTutorialDto): Promise<Tutorial> {
        const cleanVideoUrl = (dto.videoUrl || '').trim();
        const videoId = this.youtubeMetadataService.extractVideoId(cleanVideoUrl);

        let finalTitle = dto.title?.trim();
        let finalThumbnail = dto.thumbnailUrl?.trim();
        let finalDuration = dto.duration?.trim() || '2:30';

        // Auto-fetch YouTube metadata if missing
        if (videoId) {
            if (!finalThumbnail) {
                finalThumbnail = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
            }

            try {
                const meta = await this.youtubeMetadataService.getVideoMetadata(cleanVideoUrl);
                if (meta.success) {
                    if (!finalTitle && meta.title) {
                        finalTitle = meta.title;
                    }
                    if (meta.durationFormatted) {
                        finalDuration = meta.durationFormatted;
                    }
                    if (meta.thumbnail && (!finalThumbnail || finalThumbnail.includes('hqdefault'))) {
                        finalThumbnail = meta.thumbnail;
                    }
                }
            } catch (err) {
                this.logger.warn(`Could not fetch YouTube metadata for ${cleanVideoUrl}: ${err.message}`);
            }
        }

        const tutorial = await this.tutorialRepo.create({
            title: finalTitle || 'Untitled Video Tutorial',
            description: dto.description?.trim(),
            videoUrl: cleanVideoUrl,
            youtubeVideoId: videoId || undefined,
            thumbnailUrl: finalThumbnail,
            category: dto.category?.trim() || 'General',
            tags: dto.tags?.trim() || '',
            targetAudience: dto.targetAudience?.trim().toLowerCase() || 'buyer',
            displayOrder: dto.displayOrder !== undefined ? Number(dto.displayOrder) : 0,
            duration: finalDuration,
            isActive: dto.isActive !== undefined ? Boolean(dto.isActive) : true,
        });

        this.logger.log(`Created tutorial [${tutorial.id}] "${tutorial.title}" for audience: ${tutorial.targetAudience}`);
        return tutorial;
    }

    async updateTutorial(id: string, dto: UpdateTutorialDto): Promise<Tutorial> {
        const existing = await this.getTutorialById(id);

        const updateData: Partial<Tutorial> = {};

        if (dto.title !== undefined) updateData.title = dto.title.trim();
        if (dto.description !== undefined) updateData.description = dto.description.trim();
        if (dto.category !== undefined) updateData.category = dto.category.trim();
        if (dto.tags !== undefined) updateData.tags = dto.tags.trim();
        if (dto.targetAudience !== undefined) updateData.targetAudience = dto.targetAudience.trim().toLowerCase();
        if (dto.displayOrder !== undefined) updateData.displayOrder = Number(dto.displayOrder);
        if (dto.duration !== undefined) updateData.duration = dto.duration.trim();
        if (dto.isActive !== undefined) updateData.isActive = Boolean(dto.isActive);

        if (dto.videoUrl !== undefined && dto.videoUrl.trim() !== existing.videoUrl) {
            const cleanUrl = dto.videoUrl.trim();
            updateData.videoUrl = cleanUrl;
            const videoId = this.youtubeMetadataService.extractVideoId(cleanUrl);
            updateData.youtubeVideoId = videoId || undefined;
            if (!dto.thumbnailUrl && videoId) {
                updateData.thumbnailUrl = `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`;
            }
        }

        if (dto.thumbnailUrl !== undefined) {
            updateData.thumbnailUrl = dto.thumbnailUrl.trim();
        }

        const updated = await this.tutorialRepo.update(id, updateData);
        if (!updated) {
            throw new NotFoundException(`Tutorial with ID ${id} not found`);
        }
        return updated;
    }

    async deleteTutorial(id: string): Promise<boolean> {
        await this.getTutorialById(id);
        return this.tutorialRepo.delete(id);
    }

    async toggleStatus(id: string): Promise<Tutorial> {
        const item = await this.getTutorialById(id);
        const updated = await this.tutorialRepo.update(id, { isActive: !item.isActive });
        return updated!;
    }

    async reorder(items: { id: string; displayOrder: number }[]): Promise<void> {
        for (const item of items) {
            if (item.id && item.displayOrder !== undefined) {
                await this.tutorialRepo.update(item.id, { displayOrder: Number(item.displayOrder) });
            }
        }
    }

    async recordView(id: string): Promise<void> {
        await this.tutorialRepo.incrementViews(id);
    }
}
