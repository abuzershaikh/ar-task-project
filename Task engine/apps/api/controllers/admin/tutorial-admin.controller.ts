import {
    Controller,
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Param,
    Body,
    Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TutorialService, CreateTutorialDto, UpdateTutorialDto } from '../../../../tutorial-engine/services/tutorial.service';
import { Roles } from '../../../../shared/auth/decorators/roles.decorator';
import { UserRole } from '../../../../shared/database/entities/user.entity';

@ApiTags('Admin - Tutorial Engine')
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth('bearer')
@Controller('admin/tutorials')
export class AdminTutorialController {
    constructor(
        private readonly tutorialService: TutorialService,
    ) { }

    @Get()
    @ApiOperation({ summary: 'List all tutorials with filter options (Admin)' })
    @ApiQuery({ name: 'targetAudience', required: false, enum: ['buyer', 'worker', 'all'] })
    @ApiQuery({ name: 'category', required: false, type: String })
    @ApiQuery({ name: 'search', required: false, type: String })
    @ApiQuery({ name: 'isActive', required: false, type: Boolean })
    async listTutorials(
        @Query('targetAudience') targetAudience?: string,
        @Query('category') category?: string,
        @Query('search') search?: string,
        @Query('isActive') isActive?: string,
    ) {
        let activeFilter: boolean | undefined = undefined;
        if (isActive === 'true' || isActive === '1') activeFilter = true;
        if (isActive === 'false' || isActive === '0') activeFilter = false;

        const tutorials = await this.tutorialService.listTutorials({
            targetAudience,
            category,
            search,
            isActive: activeFilter,
        });

        return {
            success: true,
            tutorials,
            total: tutorials.length,
        };
    }

    @Get('categories')
    @ApiOperation({ summary: 'Get list of existing tutorial categories' })
    async getCategories(@Query('targetAudience') targetAudience?: string) {
        const categories = await this.tutorialService.getCategories(targetAudience);
        return {
            success: true,
            categories,
        };
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get tutorial by ID' })
    async getTutorial(@Param('id') id: string) {
        const tutorial = await this.tutorialService.getTutorialById(id);
        return {
            success: true,
            tutorial,
        };
    }

    @Post()
    @ApiOperation({ summary: 'Create new video tutorial' })
    async createTutorial(@Body() body: CreateTutorialDto) {
        const tutorial = await this.tutorialService.createTutorial(body);
        return {
            success: true,
            tutorial,
            message: 'Tutorial created successfully',
        };
    }

    @Put(':id')
    @ApiOperation({ summary: 'Update existing video tutorial' })
    async updateTutorial(
        @Param('id') id: string,
        @Body() body: UpdateTutorialDto,
    ) {
        const tutorial = await this.tutorialService.updateTutorial(id, body);
        return {
            success: true,
            tutorial,
            message: 'Tutorial updated successfully',
        };
    }

    @Patch(':id/toggle-status')
    @ApiOperation({ summary: 'Quick toggle active/inactive status' })
    async toggleStatus(@Param('id') id: string) {
        const tutorial = await this.tutorialService.toggleStatus(id);
        return {
            success: true,
            tutorial,
            message: `Tutorial is now ${tutorial.isActive ? 'active' : 'inactive'}`,
        };
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete video tutorial' })
    async deleteTutorial(@Param('id') id: string) {
        await this.tutorialService.deleteTutorial(id);
        return {
            success: true,
            message: 'Tutorial deleted successfully',
        };
    }

    @Post('reorder')
    @ApiOperation({ summary: 'Update display order for multiple tutorials' })
    async reorder(@Body() body: { items: { id: string; displayOrder: number }[] }) {
        if (body.items && Array.isArray(body.items)) {
            await this.tutorialService.reorder(body.items);
        }
        return {
            success: true,
            message: 'Order updated successfully',
        };
    }
}
