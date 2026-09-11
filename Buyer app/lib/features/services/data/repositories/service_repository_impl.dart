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
          final List list = response.data['services'] ?? response.data['data'] ?? [];
          final remoteServices = <ServiceModel>[];
          for (var item in list) {
            try {
              if (item is Map) {
                remoteServices.add(ServiceModel.fromJson(Map<String, dynamic>.from(item)));
              }
            } catch (err) {
              // Log item failure without aborting other services
            }
          }

          if (remoteServices.isNotEmpty) {
            final Map<String, ServiceModel> merged = {
              for (var s in fallback) s.code: s,
            };
            for (var s in remoteServices) {
              merged[s.code] = s;
            }
            return merged.values.where((s) {
              final c = s.code.toUpperCase();
              final cat = s.category.toUpperCase();
              final n = s.name.toUpperCase();
              return !c.contains('TELEGRAM') && !cat.contains('TELEGRAM') && !n.contains('TELEGRAM');
            }).toList();
          }
        }
      } catch (_) {
        // Fallback gracefully on network error
      }
    }

    return fallback.where((s) {
      final c = s.code.toUpperCase();
      final cat = s.category.toUpperCase();
      final n = s.name.toUpperCase();
      return !c.contains('TELEGRAM') && !cat.contains('TELEGRAM') && !n.contains('TELEGRAM');
    }).toList();
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
      ServiceModel(
        id: 'srv_yt_combo',
        code: 'YOUTUBE_COMBO',
        name: 'YouTube Growth Combo (Watch + Like + Sub + Comment)',
        description: 'All-in-one viral package: Watch video, Like, Subscribe to channel, and post relevant AI-generated comment.',
        category: 'YouTube',
        serviceType: 'combo',
        isActive: true,
        aiGeneratorEnabled: true,
        aiGeneratorConfig: const {
          'enabled': true,
          'generator_type': 'youtube_comment',
          'generatorType': 'youtube_comment',
          'language': 'English',
          'tone': 'natural',
        },
        currentVersion: 1,
        linkFieldLabel: 'YouTube Video URL',
        linkFieldPlaceholder: 'https://www.youtube.com/watch?v=... or https://youtu.be/...',
        textFieldLabel: 'Video Topic / Comment Instructions',
        textFieldPlaceholder: 'e.g. Loved the tutorial, clear and helpful explanations',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 8.0,
          unitPrice: 8.0,
          minQuantity: 5,
          maxQuantity: 2000,
          adminMarginPercent: 20.0,
          workerReward: 6.0,
        ),
        elements: const [
          TemplateElement(
            id: 'el_yt_combo_head',
            key: 'heading_yt_combo',
            label: 'YouTube Combo (Watch + Like + Sub + Comment)',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_yt_combo_url',
            key: 'video_url',
            label: 'YouTube Video URL',
            category: ElementCategory.input,
            type: ElementType.textField,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.buyerInput,
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
        name: 'Instagram Engagement Combo (Like + Follow)',
        description: 'Boost profile authority and post reach: Real users follow profile and like post/reel.',
        category: 'Instagram',
        serviceType: 'combo',
        isActive: true,
        aiGeneratorEnabled: false,
        currentVersion: 1,
        linkFieldLabel: 'Instagram Profile URL (or Post/Reel URL)',
        linkFieldPlaceholder: 'https://www.instagram.com/your_username or /p/...',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 2.50,
          unitPrice: 2.50,
          minQuantity: 10,
          maxQuantity: 5000,
          adminMarginPercent: 20.0,
          workerReward: 2.00,
        ),
        elements: const [
          TemplateElement(
            id: 'el_insta_combo_head',
            key: 'heading_insta_combo',
            label: 'Instagram Engagement Combo (Like + Follow)',
            category: ElementCategory.display,
            type: ElementType.heading,
            visibility: VisibilityContext.both,
            editability: EditabilityMode.adminFixed,
          ),
          TemplateElement(
            id: 'el_insta_combo_url',
            key: 'target_url',
            label: 'Instagram Profile or Post Link',
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
        category: 'Website Traffic',
        description: 'Drive high-quality direct visitors to your blog or website landing page.',
        isActive: true,
        currentVersion: 1,
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 1.20,
          unitPrice: 1.20,
          minQuantity: 10,
          maxQuantity: 10000,
          adminMarginPercent: 20.0,
          workerReward: 0.96,
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
      // ── GOOGLE PLAY STORE SERVICES ──
      ServiceModel(
        id: 'srv_play_rating',
        code: 'PLAYSTORE_RATING',
        name: 'Play Store 5-Star Rating (Only)',
        description: 'Download app and give authentic 5-Star Rating on Google Play Store.',
        category: 'Google Play Store',
        serviceType: 'rating',
        isActive: true,
        currentVersion: 1,
        linkFieldLabel: 'Play Store App Link / Package ID',
        linkFieldPlaceholder: 'https://play.google.com/store/apps/details?id=...',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 4.0,
          unitPrice: 4.0,
          minQuantity: 5,
          maxQuantity: 5000,
          adminMarginPercent: 20.0,
          workerReward: 3.20,
        ),
        elements: const [],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_play_review',
        code: 'PLAYSTORE_REVIEW',
        name: 'Play Store 5-Star Rating & Review',
        description: 'Download app, give authentic 5-Star Rating and post custom AI review on Google Play Store.',
        category: 'Google Play Store',
        serviceType: 'review',
        isActive: true,
        aiGeneratorEnabled: true,
        aiGeneratorConfig: const {
          'enabled': true,
          'generator_type': 'playstore_review',
          'language': 'English',
          'tone': 'natural',
        },
        currentVersion: 1,
        linkFieldLabel: 'Play Store App Link / Package ID',
        linkFieldPlaceholder: 'https://play.google.com/store/apps/details?id=...',
        textFieldLabel: 'App Review Focus / Key Features',
        textFieldPlaceholder: 'e.g. smooth UI, fast performance, highly recommended',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 8.0,
          unitPrice: 8.0,
          minQuantity: 5,
          maxQuantity: 5000,
          adminMarginPercent: 20.0,
          workerReward: 6.40,
        ),
        elements: const [],
        updatedAt: DateTime.now(),
      ),
      // ── GOOGLE BUSINESS / MAPS SERVICES ──
      ServiceModel(
        id: 'srv_gmb_rating',
        code: 'GOOGLE_BUSINESS_RATING',
        name: 'Google Business 5-Star Rating (Only)',
        description: 'Open Google Maps listing and give authentic 5-Star Rating.',
        category: 'Google Business',
        serviceType: 'rating',
        isActive: true,
        currentVersion: 1,
        linkFieldLabel: 'Google Maps / Business Link or Search Query',
        linkFieldPlaceholder: 'https://maps.app.goo.gl/... or Store Name, City',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 5.0,
          unitPrice: 5.0,
          minQuantity: 5,
          maxQuantity: 5000,
          adminMarginPercent: 30.0,
          workerReward: 3.50,
        ),
        elements: const [],
        updatedAt: DateTime.now(),
      ),
      ServiceModel(
        id: 'srv_gmb_review',
        code: 'GOOGLE_BUSINESS_REVIEW',
        name: 'Google Business 5-Star Rating & Review',
        description: 'Open Google Maps listing, give authentic 5-Star Rating and post custom AI review.',
        category: 'Google Business',
        serviceType: 'review',
        isActive: true,
        aiGeneratorEnabled: true,
        aiGeneratorConfig: const {
          'enabled': true,
          'generator_type': 'google_business_review',
          'language': 'English',
          'tone': 'natural',
        },
        currentVersion: 1,
        linkFieldLabel: 'Google Maps / Business Link or Search Query',
        linkFieldPlaceholder: 'https://maps.app.goo.gl/... or Store Name, City',
        textFieldLabel: 'Review Focus / Business Highlights',
        textFieldPlaceholder: 'e.g. delicious food, polite staff, fast delivery, clean ambiance',
        pricing: const PricingConfig(
          modelType: PricingModelType.countBased,
          buyerPrice: 10.0,
          unitPrice: 10.0,
          minQuantity: 5,
          maxQuantity: 5000,
          adminMarginPercent: 30.0,
          workerReward: 7.00,
        ),
        elements: const [],
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
