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

class LoadPendingReviewsEvent extends ReviewsEvent {}

class ApproveReviewEvent extends ReviewsEvent {
  final String submissionId;
  final String? notes;
  const ApproveReviewEvent(this.submissionId, {this.notes});
  @override
  List<Object?> get props => [submissionId, notes];
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
  const ReviewsLoaded(this.submissions);
  @override
  List<Object?> get props => [submissions];
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
      result.fold(
        (failure) => emit(ReviewsError(failure.message)),
        (submissions) => emit(ReviewsLoaded(submissions)),
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
            add(LoadPendingReviewsEvent());
          } else {
            emit(const ReviewsError('Failed to approve submission'));
          }
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
            add(LoadPendingReviewsEvent());
          } else {
            emit(const ReviewsError('Failed to reject submission'));
          }
        },
      );
    });
  }
}
