import { BadRequestException } from '@nestjs/common';

export class TimingPolicy {
    static readonly MIN_ACCEPT_HOURS = 1;
    static readonly MAX_ACCEPT_HOURS = 72;

    static readonly MIN_COMPLETE_HOURS = 1;
    static readonly MAX_COMPLETE_HOURS = 168; // 7 days

    static validateTiming(timeToAcceptHours?: number, timeToCompleteHours?: number): void {
        if (timeToAcceptHours !== undefined) {
            if (timeToAcceptHours < this.MIN_ACCEPT_HOURS || timeToAcceptHours > this.MAX_ACCEPT_HOURS) {
                throw new BadRequestException(
                    `timeToAcceptHours (${timeToAcceptHours}) must be between ${this.MIN_ACCEPT_HOURS} and ${this.MAX_ACCEPT_HOURS} hours`,
                );
            }
        }

        if (timeToCompleteHours !== undefined) {
            if (timeToCompleteHours < this.MIN_COMPLETE_HOURS || timeToCompleteHours > this.MAX_COMPLETE_HOURS) {
                throw new BadRequestException(
                    `timeToCompleteHours (${timeToCompleteHours}) must be between ${this.MIN_COMPLETE_HOURS} and ${this.MAX_COMPLETE_HOURS} hours`,
                );
            }
        }
    }
}
