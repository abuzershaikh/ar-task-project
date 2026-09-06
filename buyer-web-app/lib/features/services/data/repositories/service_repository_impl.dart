import 'package:get_it/get_it.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/service_model.dart';
import '../../domain/models/pricing_config.dart';
import '../../domain/models/element_category.dart';
import '../../domain/models/element_type.dart';
import '../../domain/models/template_element.dart';
import '../../domain/models/visibility_context.dart';
import '../../domain/models/editability_mode.dart';
import '../../domain/repositories/service_repository.dart';

/// ServiceRepositoryImpl (Enterprise Clean Architecture Data Layer)
/// Real backend API integration via Dio client + offline fallback templates.
class ServiceRepositoryImpl implements ServiceRepository {
  final DioClient? dioClient;

  ServiceRepositoryImpl({DioClient? dioClient})
      : dioClient = dioClient ?? (GetIt.instance.isRegistered<DioClient>() ? GetIt.instance<DioClient>() : null);

  @override
  Future<List<ServiceModel>> getPublishedServices() async {
    final fallback = _getFallbackServices();
    if (dioClient != null) {
      try {
        // Backend API request to fetch published services
        final response = await dioClient!.get('/buyer/services');
        if (response.statusCode == 200 && response.data != null) {
          final List list = response.data['services'] ?? response.data['data'] ?? response.data;
          final remoteServices = list.map((json) => ServiceModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();

          final Map<String, ServiceModel> merged = {
            for (var s in fallback) s.code: s,
          };
          for (var s in remoteServices) {
            merged[s.code] = s;
          }
          return merged.values.toList();
        }
      } catch (e) {
        try {
          // Fallback to /admin/services if /buyer/services is not present
          final response = await dioClient!.get('/admin/services');
          if (response.statusCode == 200 && response.data != null) {
            final List list = response.data['services'] ?? response.data['data'] ?? [];
            final remoteServices = list.map((json) {
              final Map<String, dynamic> item = Map<String, dynamic>.from(json['service'] ?? json);
              return ServiceModel.fromJson(item);
            }).toList();

            final Map<String, ServiceModel> merged = {
              for (var s in fallback) s.code: s,
            };
            for (var s in remoteServices) {
              merged[s.code] = s;
            }
            return merged.values.toList();
          }
        } catch (_) {}
      }
    }

    return fallback;
  }

  @override
  Future<ServiceModel?> getServiceById(String serviceId) async {
    if (dioClient != null) {
      try {
        final response = await dioClient!.get('/buyer/services/$serviceId');
        if (response.statusCode == 200 && response.data != null) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(response.data['service'] ?? response.data['data'] ?? response.data);
          return ServiceModel.fromJson(data);
        }
      } catch (_) {}
    }

    final services = await getPublishedServices();
    try {
      return services.firstWhere((s) => s.id == serviceId);
    } catch (_) {
      return services.first;
    }
  }

  /// Submit Campaign Payload to Backend API (/api/v1/buyer/orders)
  Future<bool> submitCampaignOrder(Map<String, dynamic> payloadData) async {
    if (dioClient != null) {
      try {
        final response = await dioClient!.post(
          '/buyer/orders',
          data: payloadData,
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        rethrow;
      }
    }
    return false;
  }


  List<ServiceModel> _getFallbackServices() {
    return [
      ServiceModel(
        id: 'srv_yt_subs',
        code: 'YOUTUBE_SUBSCRIBE',
        name: 'YouTube Channel Subscribers',
        description: 'Get real organic Subscribers for your YouTube channel with high retention.',
        isActive: true,
        currentVersion: 1,
        pricing: const PricingConfig(
          modelType: PricingModelType.tieredChips,
          buyerPrice: 199.0,
          adminMarginPercent: 20.0,
          workerReward: 159.2,
          chips: [
            PriceChipModel(id: 'chip_1', label: '100 Subscribers', quantity: 100, price: 199.0),
            PriceChipModel(id: 'chip_2', label: '500 Subscribers', quantity: 500, price: 899.0, isPopular: true),
            PriceChipModel(id: 'chip_3', label: '1,000 Subscribers', quantity: 1000, price: 1699.0),
          ],
        ),
        elements: const [
          TemplateElement(
            id: 'el_yt_head',
            key: 'heading_yt',
            label: 'Subscribe to YouTube Channel',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_yt_url',
            key: 'channel_url',
            label: 'YouTube Channel Link / URL',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
          TemplateElement(
            id: 'el_yt_notes',
            key: 'buyer_instructions',
            label: 'Special Instructions for Workers',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: false,
          ),
          TemplateElement(
            id: 'el_proof_scr',
            key: 'system_screenshot_proof',
            label: 'Screenshot Proof Verification',
            category: ElementCategory.system,
            type: ElementType.systemProof,
            visibility: VisibilityContext.workerOnly,
            editability: EditabilityMode.systemCalculated,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
      // ── INSTAGRAM SERVICES ──
      ServiceModel(
        id: 'srv_insta_followers',
        code: 'INSTAGRAM_FOLLOW',
        name: 'Instagram Profile Followers',
        description: 'Permanent real organic followers from verified active profiles to boost page authority.',
        category: 'Instagram',
        serviceType: 'follow',
        isActive: true,
        currentVersion: 1,
        linkFieldLabel: 'Instagram Profile URL / Username',
        linkFieldPlaceholder: 'https://instagram.com/your_username',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 2.0,
          unitPrice: 2.0,
          minQuantity: 25,
          maxQuantity: 10000,
          adminMarginPercent: 20.0,
          workerReward: 1.6,
        ),
        elements: const [
          TemplateElement(
            id: 'el_insta_follow_head',
            key: 'heading_insta_follow',
            label: 'Follow Instagram Profile',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_insta_follow_handle',
            key: 'instagram_handle',
            label: 'Instagram Profile Link / Username',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_insta_likes',
        code: 'INSTAGRAM_LIKE',
        name: 'Instagram Post & Reel Likes',
        description: 'Instant genuine likes on posts and reels from real users to boost explore algorithm placement.',
        category: 'Instagram',
        serviceType: 'like',
        isActive: true,
        currentVersion: 1,
        linkFieldLabel: 'Instagram Post / Reel URL',
        linkFieldPlaceholder: 'https://www.instagram.com/p/... or /reel/...',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 0.80,
          unitPrice: 0.80,
          minQuantity: 50,
          maxQuantity: 20000,
          adminMarginPercent: 20.0,
          workerReward: 0.64,
        ),
        elements: const [
          TemplateElement(
            id: 'el_insta_like_head',
            key: 'heading_insta_like',
            label: 'Like Instagram Post / Reel',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_insta_like_url',
            key: 'post_url',
            label: 'Instagram Post / Reel URL',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_insta_comments',
        code: 'INSTAGRAM_COMMENT',
        name: 'Instagram Relevant Comments',
        description: 'Contextual human-like comments on your Instagram posts to boost genuine discussions and reach.',
        category: 'Instagram',
        serviceType: 'comment',
        isActive: true,
        aiGeneratorEnabled: true,
        aiGeneratorConfig: const {
          'platform': 'instagram',
          'generatorType': 'instagram_comment',
        },
        currentVersion: 1,
        linkFieldLabel: 'Instagram Post / Reel URL',
        linkFieldPlaceholder: 'https://www.instagram.com/p/... or /reel/...',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 2.50,
          unitPrice: 2.50,
          minQuantity: 10,
          maxQuantity: 2000,
          adminMarginPercent: 20.0,
          workerReward: 2.0,
        ),
        elements: const [
          TemplateElement(
            id: 'el_insta_comment_head',
            key: 'heading_insta_comment',
            label: 'Instagram Contextual Comments',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_insta_comment_url',
            key: 'post_url',
            label: 'Instagram Post / Reel URL',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_insta_combo',
        code: 'INSTAGRAM_COMBO',
        name: 'Instagram All-in-One Growth Combo',
        description: 'Maximum viral traction: Real users Follow profile, Like post/reel, and leave topic-relevant Comments.',
        category: 'Instagram',
        serviceType: 'combo',
        isActive: true,
        aiGeneratorEnabled: true,
        aiGeneratorConfig: const {
          'platform': 'instagram',
          'generatorType': 'instagram_combo',
        },
        currentVersion: 1,
        linkFieldLabel: 'Instagram Post / Reel URL (or Profile URL)',
        linkFieldPlaceholder: 'https://www.instagram.com/p/... or /reel/...',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 4.50,
          unitPrice: 4.50,
          minQuantity: 10,
          maxQuantity: 2000,
          adminMarginPercent: 20.0,
          workerReward: 3.60,
        ),
        elements: const [
          TemplateElement(
            id: 'el_insta_combo_head',
            key: 'heading_insta_combo',
            label: 'Instagram Growth Combo (Follow + Like + Comment)',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_insta_combo_url',
            key: 'target_url',
            label: 'Instagram Post or Profile Link',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_web_visits',
        code: 'WEBSITE_VISITS',
        name: 'Website Targeted Traffic & Visits',
        description: 'Drive high-quality direct visitors to your blog or website landing page.',
        isActive: true,
        currentVersion: 1,
        pricing: const PricingConfig(
          modelType: PricingModelType.fixed,
          buyerPrice: 299.0,
          adminMarginPercent: 15.0,
          workerReward: 254.15,
        ),
        elements: const [
          TemplateElement(
            id: 'el_web_head',
            key: 'heading_web',
            label: 'Website Visit & Read Campaign',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_web_url',
            key: 'target_website_url',
            label: 'Website Target Landing Page URL',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
            isRequired: true,
          ),
        ],
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
