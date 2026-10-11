import {
    Controller,
    Get,
    Post,
    Param,
    Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { TutorialService } from '../../../../tutorial-engine/services/tutorial.service';
import { Public } from '../../../../shared/auth/decorators/public.decorator';

@ApiTags('Buyer - Video Tutorials')
@Controller('buyer/tutorials')
export class BuyerTutorialController {
    constructor(
        private readonly tutorialService: TutorialService,
    ) { }

    @Public()
    @Get()
    @ApiOperation({ summary: 'Get active video tutorials for Buyers' })
    @ApiQuery({ name: 'category', required: false, type: String })
    @ApiQuery({ name: 'q', required: false, type: String })
    @ApiQuery({ name: 'search', required: false, type: String })
    async getBuyerTutorials(
        @Query('category') category?: string,
        @Query('q') q?: string,
        @Query('search') search?: string,
    ) {
        const searchTerm = q || search;
        const tutorials = await this.tutorialService.listTutorials({
            targetAudience: 'buyer',
            category,
            search: searchTerm,
            isActive: true,
        });

        return {
            success: true,
            tutorials,
            total: tutorials.length,
        };
    }

    @Public()
    @Get('categories')
    @ApiOperation({ summary: 'Get available tutorial categories for Buyer filter chips' })
    async getCategories() {
        const categories = await this.tutorialService.getCategories('buyer');
        return {
            success: true,
            categories: ['All', ...categories.filter(c => c !== 'All')],
        };
    }

    @Public()
    @Post(':id/view')
    @ApiOperation({ summary: 'Record video tutorial view' })
    async recordView(@Param('id') id: string) {
        await this.tutorialService.recordView(id);
        return {
            success: true,
        };
    }
}
