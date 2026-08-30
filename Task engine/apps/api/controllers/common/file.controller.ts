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

import { Public } from '../../../../shared/auth/decorators/public.decorator';

@ApiTags('Files')
@Controller('files')
export class FileController {
    constructor(
        private readonly fileStorage: FileStorageService,
        private readonly fileRepo: FileRepository,
    ) { }

    @Post('upload')
    @ApiBearerAuth('bearer')
    @ApiOperation({ summary: 'Upload a file (proof, image, audio, doc)' })
    @ApiConsumes('multipart/form-data')
    @UseInterceptors(FileInterceptor('file', {
        limits: {
            fileSize: 25 * 1024 * 1024, // 25 MB limit
        },
        fileFilter: (req, file, cb) => {
            const rawMime = (file.mimetype || '').toLowerCase();
            const originalName = (file.originalname || '').toLowerCase();
            const ext = originalName.split('.').pop() || '';
            const validExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf', 'm4a', 'mp4', 'mp3', 'wav', 'aac', 'ogg', 'webm'];

            if (
                rawMime.startsWith('image/') ||
                rawMime.startsWith('audio/') ||
                rawMime.startsWith('video/') ||
                rawMime === 'application/pdf' ||
                validExtensions.includes(ext) ||
                rawMime === 'application/octet-stream'
            ) {
                cb(null, true);
            } else {
                cb(new BadRequestException(`Invalid file type (${rawMime}). Supported types: images, audio, video, and PDF.`), false);
            }
        },
    }))
    async uploadFile(
        @UploadedFile() file: any,
        @CurrentUser() user: User,
    ) {
        if (!file) {
            throw new BadRequestException('No file provided or file type rejected');
        }

        const originalName = (file.originalname || 'upload.png').toLowerCase();
        const ext = originalName.split('.').pop() || 'png';
        let mimeType = file.mimetype;
        if (!mimeType || mimeType === 'application/octet-stream') {
            if (['jpg', 'jpeg'].includes(ext)) mimeType = 'image/jpeg';
            else if (ext === 'png') mimeType = 'image/png';
            else if (ext === 'webp') mimeType = 'image/webp';
            else if (ext === 'gif') mimeType = 'image/gif';
            else if (ext === 'pdf') mimeType = 'application/pdf';
            else if (['mp3', 'm4a', 'wav', 'aac', 'ogg'].includes(ext)) mimeType = `audio/${ext === 'mp3' ? 'mpeg' : ext}`;
            else if (['mp4', 'webm'].includes(ext)) mimeType = `video/${ext}`;
            else mimeType = 'image/jpeg';
        }

        let type = FileType.DOCUMENT;
        if (mimeType.startsWith('image/')) type = FileType.IMAGE;
        else if (mimeType.startsWith('video/')) type = FileType.VIDEO;
        else if (mimeType.startsWith('audio/')) type = FileType.AUDIO;

        const savedFile = await this.fileStorage.saveFile({
            uploadedBy: user ? user.id : 'system',
            type,
            originalName: file.originalname || `proof_${Date.now()}.${ext}`,
            mimeType,
            buffer: file.buffer,
        });

        const appUrl = process.env.APP_URL || 'http://65.20.77.112:3000';
        const publicUrl = `${appUrl}/api/v1/files/raw/${savedFile.id}`;

        return {
            success: true,
            url: publicUrl,
            file: {
                id: savedFile.id,
                originalName: savedFile.originalName,
                mimeType: savedFile.mimeType,
                fileSize: savedFile.fileSize,
                filePath: savedFile.filePath,
                url: publicUrl,
                createdAt: savedFile.createdAt,
            },
        };
    }

    @Public()
    @Get('raw/:id')
    @ApiOperation({ summary: 'Public stream / raw file content by ID for audio guides and media' })
    async streamRawFile(
        @Param('id') fileId: string,
        @Res() res: Response,
    ) {
        const { stream, file } = await this.fileStorage.getFileStream(fileId);
        res.setHeader('Content-Type', file.mimeType || 'image/jpeg');
        res.setHeader('Content-Disposition', `inline; filename="${file.originalName}"`);
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        stream.pipe(res);
    }

    @Public()
    @Get('stream/:id')
    @ApiOperation({ summary: 'Public stream media endpoint' })
    async streamMediaFile(
        @Param('id') fileId: string,
        @Res() res: Response,
    ) {
        const { stream, file } = await this.fileStorage.getFileStream(fileId);
        res.setHeader('Content-Type', file.mimeType || 'image/jpeg');
        res.setHeader('Content-Disposition', `inline; filename="${file.originalName}"`);
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        stream.pipe(res);
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
            user &&
            user.role !== UserRole.ADMIN &&
            user.role !== UserRole.SUPER_ADMIN &&
            file.uploadedBy !== user.id &&
            user.role !== UserRole.BUYER
        ) {
            throw new ForbiddenException('Access denied to file');
        }

        res.setHeader('Content-Type', file.mimeType);
        res.setHeader('Content-Disposition', `inline; filename="${file.originalName}"`);
        res.setHeader('Access-Control-Allow-Origin', '*');
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
