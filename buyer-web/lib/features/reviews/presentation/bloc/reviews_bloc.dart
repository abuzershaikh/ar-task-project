import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/review_submission_model.dart';
import '../../data/repositories/review_repository.dart';

// Events
abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingReviewsEvent extends ReviewsEvent {
  final String? orderId;
  const LoadPendingReviewsEvent({this.orderId});
  @override
  List<Object?> get props => [orderId];
}

class ApproveReviewEvent extends ReviewsEvent {
  final String submissionId;
  final String? notes;
  const ApproveReviewEvent(this.submissionId, {this.notes});
  @override
  List<Object?> get props => [submissionId, notes];
}

class ApproveAllReviewsEvent extends ReviewsEvent {
  final String? orderId;
  final List<String>? submissionIds;
  final String? notes;
  const ApproveAllReviewsEvent({this.orderId, this.submissionIds, this.notes});
  @override
  List<Object?> get props => [orderId, submissionIds, notes];
}

class ToggleAutoApproveEvent extends ReviewsEvent {
  final bool autoApprove;
  final String? orderId;
  const ToggleAutoApproveEvent({required this.autoApprove, this.orderId});
  @override
  List<Object?> get props => [autoApprove, orderId];
}

class RejectReviewEvent extends ReviewsEvent {
  final String submissionId;
  final String reasonCode;
  final String note;
  const RejectReviewEvent({
    required this.submissionId,
    required this.reasonCode,
    required this.note,
  });
  @override
  List<Object?> get props => [submissionId, reasonCode, note];
}

// States
abstract class ReviewsState extends Equatable {
  const ReviewsState();
  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}
class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<ReviewSubmissionModel> submissions;
  final bool isAutoApprove;

  const ReviewsLoaded(this.submissions, {this.isAutoApprove = false});

  ReviewsLoaded copyWith({
    List<ReviewSubmissionModel>? submissions,
    bool? isAutoApprove,
  }) {
    return ReviewsLoaded(
      submissions ?? this.submissions,
      isAutoApprove: isAutoApprove ?? this.isAutoApprove,
    );
  }

  @override
  List<Object?> get props => [submissions, isAutoApprove];
}

class ReviewsError extends ReviewsState {
  final String message;
  const ReviewsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReviewActionSuccess extends ReviewsState {
  final String message;
  const ReviewActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewRepository repository;

  ReviewsBloc({required this.repository}) : super(ReviewsInitial()) {
    on<LoadPendingReviewsEvent>((event, emit) async {
      emit(ReviewsLoading());
      final result = await repository.getPendingReviews();
      final autoApproveResult = await repository.getAutoApproveStatus(orderId: event.orderId);
      final isAuto = autoApproveResult.getOrElse(() => false);
      result.fold(
        (failure) => emit(ReviewsError(failure.message)),
        (submissions) {
          final filtered = event.orderId != null
              ? submissions.where((s) => s.orderId == event.orderId).toList()
              : submissions;
          emit(ReviewsLoaded(filtered, isAutoApprove: isAuto));
        },
      );
    });

    on<ApproveReviewEvent>((event, emit) async {
      emit(ReviewsLoading());
      final result = await repository.approveTaskProof(event.submissionId, notes: event.notes);
      result.fold(
        (failure) => emit(ReviewsError(failure.message)),
        (success) {
          if (success) {
            emit(const ReviewActionSuccess('Submission approved successfully!'));
            add(const LoadPendingReviewsEvent());
          } else {
            emit(const ReviewsError('Failed to approve submission'));
          }
        },
      );
    });

    on<ApproveAllReviewsEvent>((event, emit) async {
      emit(ReviewsLoading());
      final result = await repository.approveAllTaskProofs(
        orderId: event.orderId,
        submissionIds: event.submissionIds,
        notes: event.notes,
      );
      result.fold(
        (failure) => emit(ReviewsError(failure.message)),
        (data) {
          final count = data['approvedCount'] ?? 0;
          emit(ReviewActionSuccess('Successfully approved $count submissions in bulk!'));
          add(LoadPendingReviewsEvent(orderId: event.orderId));
        },
      );
    });

    on<ToggleAutoApproveEvent>((event, emit) async {
      final currentState = state;
      final currentSubmissions = currentState is ReviewsLoaded ? currentState.submissions : <ReviewSubmissionModel>[];
      emit(ReviewsLoaded(currentSubmissions, isAutoApprove: event.autoApprove));

      final result = await repository.toggleAutoApprove(
        autoApprove: event.autoApprove,
        orderId: event.orderId,
      );
      result.fold(
        (failure) {
          emit(ReviewsError(failure.message));
          add(LoadPendingReviewsEvent(orderId: event.orderId));
        },
        (success) {
          emit(ReviewActionSuccess(
            event.autoApprove
                ? 'Auto-approval enabled! Worker proofs will be approved automatically.'
                : 'Auto-approval disabled. Worker proofs will wait for your manual review.',
          ));
          add(LoadPendingReviewsEvent(orderId: event.orderId));
        },
      );
    });

    on<RejectReviewEvent>((event, emit) async {
      emit(ReviewsLoading());
      final result = await repository.rejectTaskProof(
        event.submissionId,
        event.reasonCode,
        event.note,
      );
      result.fold(
        (failure) => emit(ReviewsError(failure.message)),
        (success) {
          if (success) {
            emit(const ReviewActionSuccess('Submission rejected.'));
            add(const LoadPendingReviewsEvent());
          } else {
            emit(const ReviewsError('Failed to reject submission'));
          }
        },
      );
    });
  }
}
