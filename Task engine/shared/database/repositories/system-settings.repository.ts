import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SystemSetting } from '../entities/system-settings.entity';

@Injectable()
export class SystemSettingsRepository {
    constructor(
        @InjectRepository(SystemSetting)
        private readonly repo: Repository<SystemSetting>,
    ) { }

    async findAll(): Promise<SystemSetting[]> {
        return this.repo.find({ order: { key: 'ASC' } });
    }

    async findByKey(key: string): Promise<SystemSetting | null> {
        return this.repo.findOne({ where: { key } });
    }

    async set(key: string, value: any, updatedBy?: string, description?: string): Promise<SystemSetting> {
        let setting = await this.findByKey(key);
        if (setting) {
            setting.value = value;
            if (updatedBy) setting.updatedBy = updatedBy;
            if (description) setting.description = description;
            return this.repo.save(setting);
        }

        setting = this.repo.create({ key, value, updatedBy, description });
        return this.repo.save(setting);
    }
}
