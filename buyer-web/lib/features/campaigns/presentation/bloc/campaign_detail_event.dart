import 'package:equatable/equatable.dart';

abstract class CampaignDetailEvent extends Equatable {
  const CampaignDetailEvent();

  @override
  List<Object?> get props => [];
}

class GetCampaignDetailEvent extends CampaignDetailEvent {
  final String campaignId;

  const GetCampaignDetailEvent(this.campaignId);

  @override
  List<Object?> get props => [campaignId];
}

class RefreshCampaignDetailEvent extends CampaignDetailEvent {
  final String campaignId;

  const RefreshCampaignDetailEvent(this.campaignId);

  @override
  List<Object?> get props => [campaignId];
}

class PauseCampaignEvent extends CampaignDetailEvent {
  final String campaignId;

  const PauseCampaignEvent(this.campaignId);

  @override
  List<Object?> get props => [campaignId];
}

class ResumeCampaignEvent extends CampaignDetailEvent {
  final String campaignId;

  const ResumeCampaignEvent(this.campaignId);

  @override
  List<Object?> get props => [campaignId];
}

class CancelCampaignEvent extends CampaignDetailEvent {
  final String campaignId;

  const CancelCampaignEvent(this.campaignId);

  @override
  List<Object?> get props => [campaignId];
}
