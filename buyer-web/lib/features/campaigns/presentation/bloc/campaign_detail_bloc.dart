import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/campaign_detail_extensions.dart';
import '../../domain/repositories/campaign_repository.dart';
import 'campaign_detail_event.dart';
import 'campaign_detail_state.dart';

class CampaignDetailBloc
    extends Bloc<CampaignDetailEvent, CampaignDetailState> {
  final CampaignRepository repository;

  CampaignDetailBloc({required this.repository})
      : super(const CampaignDetailInitial()) {
    on<GetCampaignDetailEvent>(_onGetCampaignDetail);
    on<RefreshCampaignDetailEvent>(_onRefreshCampaignDetail);
    on<PauseCampaignEvent>(_onPauseCampaign);
    on<ResumeCampaignEvent>(_onResumeCampaign);
    on<CancelCampaignEvent>(_onCancelCampaign);
  }

  Future<void> _onGetCampaignDetail(
    GetCampaignDetailEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    emit(const CampaignDetailLoading());

    final result = await repository.getCampaignDetail(event.campaignId);

    result.fold(
      (failure) => emit(CampaignDetailError(failure.message)),
      (campaign) => emit(CampaignDetailLoaded(campaign)),
    );
  }

  Future<void> _onRefreshCampaignDetail(
    RefreshCampaignDetailEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    final result = await repository.getCampaignDetail(event.campaignId);

    result.fold(
      (failure) => emit(CampaignDetailError(failure.message)),
      (campaign) => emit(CampaignDetailLoaded(campaign)),
    );
  }

  Future<void> _onPauseCampaign(
    PauseCampaignEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    if (state is! CampaignDetailLoaded) return;

    final result = await repository.pauseCampaign(event.campaignId);

    result.fold(
      (failure) => emit(CampaignDetailError(failure.message)),
      (campaign) => emit(CampaignActionSuccess('Campaign paused', campaign)),
    );

    // Reload detail
    add(RefreshCampaignDetailEvent(event.campaignId));
  }

  Future<void> _onResumeCampaign(
    ResumeCampaignEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    if (state is! CampaignDetailLoaded) return;

    final result = await repository.resumeCampaign(event.campaignId);

    result.fold(
      (failure) => emit(CampaignDetailError(failure.message)),
      (campaign) => emit(CampaignActionSuccess('Campaign resumed', campaign)),
    );

    // Reload detail
    add(RefreshCampaignDetailEvent(event.campaignId));
  }

  Future<void> _onCancelCampaign(
    CancelCampaignEvent event,
    Emitter<CampaignDetailState> emit,
  ) async {
    if (state is! CampaignDetailLoaded) return;

    final result = await repository.cancelCampaign(event.campaignId);

    result.fold(
      (failure) => emit(CampaignDetailError(failure.message)),
      (success) {
        emit(CampaignActionSuccess(
          'Campaign cancelled',
          // Create a dummy campaign detail with cancelled status
          (state as CampaignDetailLoaded).campaign.copyWith(),
        ));
      },
    );

    // Reload detail
    add(RefreshCampaignDetailEvent(event.campaignId));
  }
}
