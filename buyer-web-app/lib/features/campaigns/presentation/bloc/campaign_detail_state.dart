import 'package:equatable/equatable.dart';
import '../../domain/entities/campaign_detail.dart';

abstract class CampaignDetailState extends Equatable {
  const CampaignDetailState();

  @override
  List<Object?> get props => [];
}

class CampaignDetailInitial extends CampaignDetailState {
  const CampaignDetailInitial();
}

class CampaignDetailLoading extends CampaignDetailState {
  const CampaignDetailLoading();
}

class CampaignDetailLoaded extends CampaignDetailState {
  final CampaignDetail campaign;

  const CampaignDetailLoaded(this.campaign);

  @override
  List<Object?> get props => [campaign];

  CampaignDetailLoaded copyWith({CampaignDetail? campaign}) {
    return CampaignDetailLoaded(campaign ?? this.campaign);
  }
}

class CampaignDetailError extends CampaignDetailState {
  final String message;

  const CampaignDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class CampaignActionSuccess extends CampaignDetailState {
  final String message;
  final CampaignDetail campaign;

  const CampaignActionSuccess(this.message, this.campaign);

  @override
  List<Object?> get props => [message, campaign];
}
