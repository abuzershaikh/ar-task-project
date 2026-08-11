import {
    Controller,
    Post,
    Get,
    Delete,
    Param,
    Res,
    UseInterceptors,
    UploadedFile,
    BadRequestException,
    ForbiddenException,
    NotFoundException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { ApiTags, ApiOperation, ApiConsumes, ApiBearerAuth } from '@nestjs/swagger';
import { FileStorageService } from '../../../../shared/services/file-storage.service';
import { FileRepository } from '../../../../shared/database/repositories/file.repository';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { User, UserRole } from '../../../../shared/database/entities/user.entity';
import { FileType } from '../../../../shared/database/entities/file.entity';

@ApiTags('Files')
@Controller('files')
export class FileController {
    constructor(
        private readonly fileStorage: FileStorageService,
        private readonly fileRepo: FileRepository,
    ) { }

    @Post('upload')
    @ApiBearerAuth('bearer')
    @ApiOperation({ summary: 'Upload a file (proof, image, doc)' })
    @ApiConsumes('multipart/form-data')
    @UseInterceptors(FileInterceptor('file'))
    async uploadFile(
        @UploadedFile() file: any,
        @CurrentUser() user: User,
    ) {
        if (!file) {
            throw new BadRequestException('No file provided');
        }

        let type = FileType.DOCUMENT;
        if (file.mimetype.startsWith('image/')) type = FileType.IMAGE;
        else if (file.mimetype.startsWith('video/')) type = FileType.VIDEO;

        const savedFile = await this.fileStorage.saveFile({
            uploadedBy: user.id,
            type,
            originalName: file.originalname,
            mimeType: file.mimetype,
            buffer: file.buffer,
        });

        return {
            success: true,
            file: {
                id: savedFile.id,
                originalName: savedFile.originalName,
                mimeType: savedFile.mimeType,
                fileSize: savedFile.fileSize,
                filePath: savedFile.filePath,
                createdAt: savedFile.createdAt,
            },
        };
    }

    @Get(':id')
    @ApiBearerAuth('bearer')
    @ApiOperation({ summary: 'Get file metadata by ID' })
    async getFileMetadata(
        @Param('id') fileId: string,
        @CurrentUser() user: User,
    ) {
        const file = await this.fileRepo.findById(fileId);
        if (!file) {
            throw new NotFoundException('File not found');
        }

        if (
            user.role !== UserRole.ADMIN &&
            user.role !== UserRole.SUPER_ADMIN &&
            file.uploadedBy !== user.id &&
            user.role !== UserRole.BUYER
        ) {
            throw new ForbiddenException('Access denied to file');
        }

        return {
            success: true,
            file: {
                id: file.id,
                uploadedBy: file.uploadedBy,
                type: file.type,
                originalName: file.originalName,
                mimeType: file.mimeType,
                fileSize: file.fileSize,
                createdAt: file.createdAt,
            },
        };
    }

    @Get(':id/download')
    @ApiBearerAuth('bearer')
    @ApiOperation({ summary: 'Download or view file content' })
    async getFile(
        @Param('id') fileId: string,
        @CurrentUser() user: User,
        @Res() res: Response,
    ) {
        const { stream, file } = await this.fileStorage.getFileStream(fileId);

        if (
            user.role !== UserRole.ADMIN &&
            user.role !== UserRole.SUPER_ADMIN &&
            file.uploadedBy !== user.id &&
            user.role !== UserRole.BUYER
        ) {
            throw new ForbiddenException('Access denied to file');
        }

        res.setHeader('Content-Type', file.mimeType);
        res.setHeader('Content-Disposition', `inline; filename="${file.originalName}"`);
        stream.pipe(res);
    }

    @Delete(':id')
    @ApiBearerAuth('bearer')
    @ApiOperation({ summary: 'Delete file by ID (Owner or Admin)' })
    async deleteFile(
        @Param('id') fileId: string,
        @CurrentUser() user: User,
    ) {
        const file = await this.fileRepo.findById(fileId);
        if (!file) {
            throw new NotFoundException('File not found');
        }

        if (
            user.role !== UserRole.ADMIN &&
            user.role !== UserRole.SUPER_ADMIN &&
            file.uploadedBy !== user.id
        ) {
            throw new ForbiddenException('Only file owner or admin can delete file');
        }

        await this.fileRepo.delete(fileId);
        return {
            success: true,
            message: 'File deleted successfully',
        };
    }
}
