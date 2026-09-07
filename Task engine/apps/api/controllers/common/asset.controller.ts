import { Controller, Get, Param, Res, NotFoundException } from '@nestjs/common';
import { Response } from 'express';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { Public } from '../../../../shared/auth/decorators/public.decorator';
import * as path from 'path';
import * as fs from 'fs';

/**
 * Public endpoint for serving self-hosted platform brand icons.
 * 
 * This avoids external CDN hotlink blocking issues (Wikimedia 403 errors)
 * by serving icons directly from the VPS filesystem.
 * 
 * Icons are stored in /opt/task-engine/assets/icons/
 */
@ApiTags('Assets')
@Controller('assets')
export class AssetController {
    private readonly iconsDir: string;

    constructor() {
        // Production: /opt/task-engine/assets/icons
        // Dev fallback: ./assets/icons
        const prodPath = '/opt/task-engine/assets/icons';
        const devPath = path.resolve(process.cwd(), 'assets', 'icons');
        this.iconsDir = fs.existsSync(prodPath) ? prodPath : devPath;
    }

    @Public()
    @Get('icons/:platform')
    @ApiOperation({ summary: 'Get platform brand icon (youtube, instagram, playstore, etc.)' })
    async getPlatformIcon(
        @Param('platform') platform: string,
        @Res() res: Response,
    ) {
        const safeName = platform.replace(/[^a-zA-Z0-9_-]/g, '').toLowerCase();
        
        // Try PNG first, then SVG
        const pngPath = path.join(this.iconsDir, `${safeName}.png`);
        const svgPath = path.join(this.iconsDir, `${safeName}.svg`);

        let filePath: string;
        let mimeType: string;

        if (fs.existsSync(pngPath)) {
            filePath = pngPath;
            mimeType = 'image/png';
        } else if (fs.existsSync(svgPath)) {
            filePath = svgPath;
            mimeType = 'image/svg+xml';
        } else {
            throw new NotFoundException(`Icon '${safeName}' not found. Available: youtube, instagram, playstore, facebook, telegram, twitter, tiktok`);
        }

        res.setHeader('Content-Type', mimeType);
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        res.setHeader('Content-Disposition', `inline; filename="${safeName}.${mimeType === 'image/png' ? 'png' : 'svg'}"`);

        const stream = fs.createReadStream(filePath);
        stream.pipe(res);
    }

    @Public()
    @Get('icons')
    @ApiOperation({ summary: 'List all available platform icons' })
    async listIcons() {
        try {
            if (!fs.existsSync(this.iconsDir)) {
                return { success: true, icons: [], message: 'Icons directory not yet configured' };
            }
            const files = fs.readdirSync(this.iconsDir)
                .filter(f => f.endsWith('.png') || f.endsWith('.svg'))
                .map(f => {
                    const name = f.replace(/\.(png|svg)$/, '');
                    const appUrl = process.env.APP_URL || 'http://65.20.77.112:3000';
                    return {
                        name,
                        url: `${appUrl}/api/v1/assets/icons/${name}`,
                        file: f,
                    };
                });
            return { success: true, icons: files };
        } catch {
            return { success: true, icons: [] };
        }
    }
}
