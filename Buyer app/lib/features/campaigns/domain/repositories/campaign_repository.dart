import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/campaign_detail.dart';

abstract class CampaignRepository {
  /// Get campaign list with filters
  Future<Either<Failure, List<CampaignDetail>>> getCampaigns({
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get detailed campaign information
  Future<Either<Failure, CampaignDetail>> getCampaignDetail(String id);

  /// Get campaign tasks with filters
  Future<Either<Failure, List<dynamic>>> getCampaignTasks(
    String id, {
    String? status,
    int page = 1,
    int limit = 20,
  });

  /// Get campaign pending reviews
  Future<Either<Failure, List<dynamic>>> getCampaignReviews(
    String id, {
    int page = 1,
    int limit = 20,
  });

  /// Get campaign activity timeline
  Future<Either<Failure, List<dynamic>>> getCampaignActivity(String id);

  /// Get campaign analytics
  Future<Either<Failure, Map<String, dynamic>>> getCampaignAnalytics(
    String id,
  );

  /// Pause campaign
  Future<Either<Failure, CampaignDetail>> pauseCampaign(String id);

  /// Resume campaign
  Future<Either<Failure, CampaignDetail>> resumeCampaign(String id);

  /// Cancel campaign
  Future<Either<Failure, void>> cancelCampaign(String id);

  /// Create new campaign
  Future<Either<Failure, CampaignDetail>> createCampaign({
    required String serviceId,
    required String name,
    required int quantity,
    required String instructions,
    required List<String> proofRequirements,
    required int acceptWithinHours,
    required int completeWithinHours,
    required DateTime deadline,
    required String reviewMode,
  });
}
