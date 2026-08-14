import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/more_repository.dart';
import '../../data/models/more_models.dart';

abstract class MoreEvent {}
class LoadKycQueueEvent extends MoreEvent {}
class VerifyKycEvent extends MoreEvent {
  final String kycId;
  VerifyKycEvent(this.kycId);
}

class LoadPayoutsQueueEvent extends MoreEvent {}
class ProcessPayoutEvent extends MoreEvent {
  final String payoutId;
  ProcessPayoutEvent(this.payoutId);
}

class LoadReviewsQueueEvent extends MoreEvent {}
class ApproveReviewEvent extends MoreEvent {
  final String reviewId;
  ApproveReviewEvent(this.reviewId);
}

class LoadAuditLogsEvent extends MoreEvent {}

abstract class MoreState {}
class MoreInitial extends MoreState {}
class MoreLoading extends MoreState {}

class KycQueueLoaded extends MoreState {
  final List<KycItemModel> items;
  KycQueueLoaded(this.items);
}

class PayoutsQueueLoaded extends MoreState {
  final List<PayoutItemModel> items;
  PayoutsQueueLoaded(this.items);
}

class ReviewsQueueLoaded extends MoreState {
  final List<ReviewItemModel> items;
  ReviewsQueueLoaded(this.items);
}

class AuditLogsLoaded extends MoreState {
  final List<AuditLogItemModel> logs;
  AuditLogsLoaded(this.logs);
}

class MoreError extends MoreState {
  final String message;
  MoreError(this.message);
}

class MoreBloc extends Bloc<MoreEvent, MoreState> {
  final MoreRepository repository;

  MoreBloc({required this.repository}) : super(MoreInitial()) {
    on<LoadKycQueueEvent>(_onLoadKyc);
    on<VerifyKycEvent>(_onVerifyKyc);
    on<LoadPayoutsQueueEvent>(_onLoadPayouts);
    on<ProcessPayoutEvent>(_onProcessPayout);
    on<LoadReviewsQueueEvent>(_onLoadReviews);
    on<ApproveReviewEvent>(_onApproveReview);
    on<LoadAuditLogsEvent>(_onLoadAuditLogs);
  }

  Future<void> _onLoadKyc(LoadKycQueueEvent event, Emitter<MoreState> emit) async {
    emit(MoreLoading());
    try {
      final items = await repository.getPendingKycQueue();
      emit(KycQueueLoaded(items));
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onVerifyKyc(VerifyKycEvent event, Emitter<MoreState> emit) async {
    try {
      await repository.verifyKyc(event.kycId);
      add(LoadKycQueueEvent());
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onLoadPayouts(LoadPayoutsQueueEvent event, Emitter<MoreState> emit) async {
    emit(MoreLoading());
    try {
      final items = await repository.getPendingPayoutsQueue();
      emit(PayoutsQueueLoaded(items));
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onProcessPayout(ProcessPayoutEvent event, Emitter<MoreState> emit) async {
    try {
      await repository.processPayout(event.payoutId);
      add(LoadPayoutsQueueEvent());
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onLoadReviews(LoadReviewsQueueEvent event, Emitter<MoreState> emit) async {
    emit(MoreLoading());
    try {
      final items = await repository.getPendingReviewsQueue();
      emit(ReviewsQueueLoaded(items));
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onApproveReview(ApproveReviewEvent event, Emitter<MoreState> emit) async {
    try {
      await repository.approveReview(event.reviewId);
      add(LoadReviewsQueueEvent());
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }

  Future<void> _onLoadAuditLogs(LoadAuditLogsEvent event, Emitter<MoreState> emit) async {
    emit(MoreLoading());
    try {
      final logs = await repository.getAuditLogs();
      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(MoreError(e.toString()));
    }
  }
}
