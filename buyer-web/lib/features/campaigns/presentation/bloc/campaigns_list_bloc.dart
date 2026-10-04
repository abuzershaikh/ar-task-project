import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/campaign_detail.dart';
import '../../domain/repositories/campaign_repository.dart';

// Events
abstract class CampaignsListEvent extends Equatable {
  const CampaignsListEvent();
  @override
  List<Object?> get props => [];
}

class LoadCampaignsListEvent extends CampaignsListEvent {
  final String? status;
  const LoadCampaignsListEvent({this.status});

  @override
  List<Object?> get props => [status];
}

class RefreshCampaignsListEvent extends CampaignsListEvent {
  final String? status;
  const RefreshCampaignsListEvent({this.status});

  @override
  List<Object?> get props => [status];
}

// States
abstract class CampaignsListState extends Equatable {
  const CampaignsListState();
  @override
  List<Object?> get props => [];
}

class CampaignsListInitial extends CampaignsListState {}

class CampaignsListLoading extends CampaignsListState {}

class CampaignsListLoaded extends CampaignsListState {
  final List<CampaignDetail> campaigns;
  final String? selectedStatus;

  const CampaignsListLoaded({required this.campaigns, this.selectedStatus});

  @override
  List<Object?> get props => [campaigns, selectedStatus];
}

class CampaignsListError extends CampaignsListState {
  final String message;
  const CampaignsListError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class CampaignsListBloc extends Bloc<CampaignsListEvent, CampaignsListState> {
  final CampaignRepository repository;

  CampaignsListBloc({required this.repository}) : super(CampaignsListInitial()) {
    on<LoadCampaignsListEvent>(_onLoadCampaigns);
    on<RefreshCampaignsListEvent>(_onRefreshCampaigns);
  }

  Future<void> _onLoadCampaigns(
    LoadCampaignsListEvent event,
    Emitter<CampaignsListState> emit,
  ) async {
    emit(CampaignsListLoading());
    final result = await repository.getCampaigns(status: event.status);
    result.fold(
      (failure) => emit(CampaignsListError(failure.message)),
      (campaigns) => emit(CampaignsListLoaded(campaigns: campaigns, selectedStatus: event.status)),
    );
  }

  Future<void> _onRefreshCampaigns(
    RefreshCampaignsListEvent event,
    Emitter<CampaignsListState> emit,
  ) async {
    final result = await repository.getCampaigns(status: event.status);
    result.fold(
      (failure) => emit(CampaignsListError(failure.message)),
      (campaigns) => emit(CampaignsListLoaded(campaigns: campaigns, selectedStatus: event.status)),
    );
  }
}
