import { Body, Controller, Get, Post } from '@nestjs/common';
import { AuthService } from '../../../../shared/auth/auth.service';
import { RegisterDto } from '../../../../shared/auth/dto/register.dto';
import { LoginDto } from '../../../../shared/auth/dto/login.dto';
import { RefreshTokenDto } from '../../../../shared/auth/dto/refresh-token.dto';
import { ForgotPasswordDto } from '../../../../shared/auth/dto/forgot-password.dto';
import { ResetPasswordDto } from '../../../../shared/auth/dto/reset-password.dto';
import { Public } from '../../../../shared/auth/decorators/public.decorator';
import { CurrentUser } from '../../../../shared/auth/decorators/current-user.decorator';
import { User } from '../../../../shared/database/entities/user.entity';

@Controller('auth')
export class AuthController {
    constructor(private readonly authService: AuthService) {}

    @Public()
    @Post('register')
    async register(@Body() dto: RegisterDto) {
        const result = await this.authService.register(dto);
        return {
            success: true,
            data: result,
            message: 'Registration successful',
        };
    }

    @Public()
    @Post('login')
    async login(@Body() dto: LoginDto) {
        const result = await this.authService.login(dto);
        return {
            success: true,
            data: result,
            message: 'Login successful',
        };
    }

    @Public()
    @Post('refresh')
    async refresh(@Body() dto: RefreshTokenDto) {
        const tokens = await this.authService.refresh(dto);
        return {
            success: true,
            data: tokens,
        };
    }

    @Public()
    @Post('forgot-password')
    async forgotPassword(@Body() dto: ForgotPasswordDto) {
        const result = await this.authService.forgotPassword(dto);
        return {
            success: true,
            data: result,
        };
    }

    @Public()
    @Post('reset-password')
    async resetPassword(@Body() dto: ResetPasswordDto) {
        const result = await this.authService.resetPassword(dto);
        return {
            success: true,
            data: result,
        };
    }

    @Post('logout')
    async logout(@CurrentUser() user: User) {
        return this.authService.logout(user.id);
    }

    @Get('me')
    async getProfile(@CurrentUser() user: User) {
        const profile = await this.authService.getProfile(user.id);
        return {
            success: true,
            data: profile,
        };
    }
}
