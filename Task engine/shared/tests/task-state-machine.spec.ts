import { TaskStateMachine } from '../../task-engine/task-state-machine';
import { TaskStatus } from '../../task-engine/types/task-status.enum';

describe('TaskStateMachine', () => {
    it('should allow valid transition from DRAFT to ACTIVE', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.DRAFT, TaskStatus.ACTIVE)).toBe(true);
    });

    it('should allow valid transition from ACTIVE to ASSIGNED', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.ACTIVE, TaskStatus.ASSIGNED)).toBe(true);
    });

    it('should allow valid transition from ASSIGNED to ACCEPTED', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.ASSIGNED, TaskStatus.ACCEPTED)).toBe(true);
    });

    it('should allow valid transition from ACCEPTED to IN_PROGRESS', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.ACCEPTED, TaskStatus.IN_PROGRESS)).toBe(true);
    });

    it('should allow valid transition from IN_PROGRESS to SUBMITTED', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.IN_PROGRESS, TaskStatus.SUBMITTED)).toBe(true);
    });

    it('should allow valid transition from SUBMITTED to UNDER_REVIEW', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.SUBMITTED, TaskStatus.UNDER_REVIEW)).toBe(true);
    });

    it('should allow valid transition from UNDER_REVIEW to APPROVED', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.UNDER_REVIEW, TaskStatus.APPROVED)).toBe(true);
    });

    it('should disallow invalid transition from DRAFT directly to APPROVED', () => {
        expect(TaskStateMachine.canTransition(TaskStatus.DRAFT, TaskStatus.APPROVED)).toBe(false);
    });

    it('should throw error on invalid transition validation', () => {
        expect(() => {
            TaskStateMachine.validateTransition(TaskStatus.APPROVED, TaskStatus.ACTIVE);
        }).toThrow();
    });

    it('should identify terminal states correctly', () => {
        expect(TaskStateMachine.isTerminalState(TaskStatus.APPROVED)).toBe(true);
        expect(TaskStateMachine.isTerminalState(TaskStatus.ACTIVE)).toBe(false);
    });
});
