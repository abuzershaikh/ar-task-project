import { Module } from '@nestjs/common';
import { DatabaseModule } from '../shared/database/database.module';
import { ServicesModule } from '../shared/services/services.module';
import { TutorialService } from './services/tutorial.service';

@Module({
    imports: [
        DatabaseModule,
        ServicesModule,
    ],
    providers: [
        TutorialService,
    ],
    exports: [
        TutorialService,
    ],
})
export class TutorialEngineModule { }
