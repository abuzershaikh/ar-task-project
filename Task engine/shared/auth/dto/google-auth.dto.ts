import { Transform } from 'class-transformer';
import { IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';
import { UserRole } from '../../database/entities/user.entity';

export class GoogleAuthDto {
    @IsNotEmpty()
    @IsString()
    idToken: string;

    @IsOptional()
    @Transform(({ value }) => (typeof value === 'string' ? value.toUpperCase() : value))
    @IsEnum(UserRole)
    role?: UserRole;
}
