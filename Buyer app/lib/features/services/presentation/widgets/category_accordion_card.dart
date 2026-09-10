import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/service_model.dart';
import '../../../../core/utils/service_unit_helper.dart';

/// Visual color theme configuration for each category card.
class CategoryCardPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDeep;
  final Color cardBgStart;
  final Color cardBgEnd;
  final Color cardBorder;
  final Color subCardBgStart;
  final Color subCardBgEnd;
  final Color iconBg;
  final Color selectBtnStart;
  final Color selectBtnEnd;

  const CategoryCardPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDeep,
    required this.cardBgStart,
    required this.cardBgEnd,
    required this.cardBorder,
    required this.subCardBgStart,
    required this.subCardBgEnd,
    required this.iconBg,
    required this.selectBtnStart,
    required this.selectBtnEnd,
  });

  static CategoryCardPalette from(String categoryName, Color fallbackColor) {
    final cat = categoryName.toUpperCase();

    // 1. YouTube -> Light Pastel Red / Coral
    if (cat.contains('YOUTUBE') ||
        cat.contains('YT') ||
        cat.contains('VIDEO')) {
      return const CategoryCardPalette(
        primary: Color(0xFFEF4444),
        primaryLight: Color(0xFFF87171),
        primaryDeep: Color(0xFFDC2626),
        cardBgStart: Color(0xFFFFF5F5),
        cardBgEnd: Color(0xFFFEE2E2),
        cardBorder: Color(0xFFFECACA),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFFFF8F8),
        iconBg: Color(0xFFFEF2F2),
        selectBtnStart: Color(0xFFF87171),
        selectBtnEnd: Color(0xFFDC2626),
      );
    }

    // 2. Google Play Store / Play Store / Reviews -> Light Pastel Emerald Green
    if (cat.contains('PLAY') ||
        cat.contains('GOOGLE') ||
        cat.contains('RATING')) {
      return const CategoryCardPalette(
        primary: Color(0xFF059669),
        primaryLight: Color(0xFF34D399),
        primaryDeep: Color(0xFF047857),
        cardBgStart: Color(0xFFF0FDF4),
        cardBgEnd: Color(0xFFDCFCE7),
        cardBorder: Color(0xFFBBF7D0),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFF8FDF9),
        iconBg: Color(0xFFECFDF5),
        selectBtnStart: Color(0xFF10B981),
        selectBtnEnd: Color(0xFF047857),
      );
    }

    // 3. App Install & Review / Mobile Apps -> Light Pastel Violet / Purple
    if (cat.contains('APP') ||
        cat.contains('INSTALL') ||
        cat.contains('MOBILE') ||
        cat.contains('DOWNLOAD')) {
      return const CategoryCardPalette(
        primary: Color(0xFF7C3AED),
        primaryLight: Color(0xFFA78BFA),
        primaryDeep: Color(0xFF6D28D9),
        cardBgStart: Color(0xFFFAF5FF),
        cardBgEnd: Color(0xFFF3E8FF),
        cardBorder: Color(0xFFE9D5FF),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFFCFAFF),
        iconBg: Color(0xFFFAF5FF),
        selectBtnStart: Color(0xFFA78BFA),
        selectBtnEnd: Color(0xFF6D28D9),
      );
    }

    // 4. Instagram -> Light Pastel Rose / Magenta
    if (cat.contains('INSTAGRAM') ||
        cat.contains('IG') ||
        cat.contains('REEL') ||
        (cat.contains('INSTA') && !cat.contains('INSTALL'))) {
      return const CategoryCardPalette(
        primary: Color(0xFFEC4899),
        primaryLight: Color(0xFFF472B6),
        primaryDeep: Color(0xFFDB2777),
        cardBgStart: Color(0xFFFDF2F8),
        cardBgEnd: Color(0xFFFCE7F3),
        cardBorder: Color(0xFFFBCFE8),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFFFF5FA),
        iconBg: Color(0xFFFDF2F8),
        selectBtnStart: Color(0xFFF472B6),
        selectBtnEnd: Color(0xFFDB2777),
      );
    }


    // 6. Website / Traffic / SEO / Web -> Light Pastel Amber / Gold
    if (cat.contains('WEB') ||
        cat.contains('TRAFFIC') ||
        cat.contains('SEO') ||
        cat.contains('VISIT')) {
      return const CategoryCardPalette(
        primary: Color(0xFFD97706),
        primaryLight: Color(0xFFFBBF24),
        primaryDeep: Color(0xFFB45309),
        cardBgStart: Color(0xFFFFFBEB),
        cardBgEnd: Color(0xFFFEF3C7),
        cardBorder: Color(0xFFFDE68A),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFFFFDF5),
        iconBg: Color(0xFFFFFBEB),
        selectBtnStart: Color(0xFFFBBF24),
        selectBtnEnd: Color(0xFFD97706),
      );
    }

    // Fallback: Presets by category hash
    final int hash = categoryName.hashCode.abs();
    final List<CategoryCardPalette> presets = [
      const CategoryCardPalette(
        primary: Color(0xFF4F46E5),
        primaryLight: Color(0xFF818CF8),
        primaryDeep: Color(0xFF3730A3),
        cardBgStart: Color(0xFFEEF2FF),
        cardBgEnd: Color(0xFFE0E7FF),
        cardBorder: Color(0xFFC7D2FE),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFF8FAFF),
        iconBg: Color(0xFFEEF2FF),
        selectBtnStart: Color(0xFF818CF8),
        selectBtnEnd: Color(0xFF4F46E5),
      ),
      const CategoryCardPalette(
        primary: Color(0xFF0D9488),
        primaryLight: Color(0xFF2DD4BF),
        primaryDeep: Color(0xFF0F766E),
        cardBgStart: Color(0xFFF0FDFA),
        cardBgEnd: Color(0xFFCCFBF1),
        cardBorder: Color(0xFF99F6E4),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFF8FFFD),
        iconBg: Color(0xFFF0FDFA),
        selectBtnStart: Color(0xFF2DD4BF),
        selectBtnEnd: Color(0xFF0D9488),
      ),
      const CategoryCardPalette(
        primary: Color(0xFFF43F5E),
        primaryLight: Color(0xFFFB7185),
        primaryDeep: Color(0xFFE11D48),
        cardBgStart: Color(0xFFFFF0F3),
        cardBgEnd: Color(0xFFFFE4E8),
        cardBorder: Color(0xFFFECDD3),
        subCardBgStart: Colors.white,
        subCardBgEnd: Color(0xFFFFF8F9),
        iconBg: Color(0xFFFFF1F2),
        selectBtnStart: Color(0xFFFB7185),
        selectBtnEnd: Color(0xFFE11D48),
      ),
    ];
    return presets[hash % presets.length];
  }
}

/// Category Accordion Card with distinct pastel color per category.
class CategoryAccordionCard extends StatefulWidget {
  final String categoryName;
  final IconData icon;
  final Color themeColor;
  final List<ServiceModel> services;
  final bool initialExpanded;
  final ValueChanged<ServiceModel> onSelectService;

  const CategoryAccordionCard({
    super.key,
    required this.categoryName,
    required this.icon,
    required this.themeColor,
    required this.services,
    this.initialExpanded = false,
    required this.onSelectService,
  });

  @override
  State<CategoryAccordionCard> createState() => _CategoryAccordionCardState();
}

class _CategoryAccordionCardState extends State<CategoryAccordionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _chevronRotation;
  late CategoryCardPalette _palette;

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _palette = CategoryCardPalette.from(widget.categoryName, widget.themeColor);
    _isExpanded = widget.initialExpanded;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );
    _chevronRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (_isExpanded) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CategoryAccordionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName ||
        oldWidget.themeColor != widget.themeColor) {
      _palette =
          CategoryCardPalette.from(widget.categoryName, widget.themeColor);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  // ── Asset Icon Resolver for Category ──
  String? _getCategoryAssetIcon(String categoryName) {
    final cat = categoryName.toUpperCase();
    if (cat.contains('PLAY') || cat.contains('GOOGLE')) {
      return 'assets/icons/google-play.png';
    }
    if (cat.contains('YOUTUBE') || cat.contains('YT') || cat.contains('VIDEO')) {
      return 'assets/icons/youtube.png';
    }
    if (cat.contains('APP') ||
        cat.contains('INSTALL') ||
        cat.contains('MOBILE') ||
        cat.contains('DOWNLOAD')) {
      return 'assets/icons/smartphone.png';
    }
    if (cat.contains('INSTAGRAM') ||
        cat.contains('IG') ||
        cat.contains('REEL') ||
        (cat.contains('INSTA') && !cat.contains('INSTALL'))) {
      return 'assets/icons/instagram.png';
    }
    if (cat.contains('CHAT')) {
      return 'assets/icons/mobile-chatting.png';
    }
    if (cat.contains('WEB') ||
        cat.contains('TRAFFIC') ||
        cat.contains('MARKETING')) {
      return 'assets/icons/marketing.png';
    }
    return null;
  }

  // ── Asset Icon Resolver for Sub-Services ──
  String? _getServiceAssetIcon(ServiceModel s) {
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();

    // Check COMBO first so combo services get marketing icon and not single subscribe icon!
    if (code.contains('COMBO') || name.contains('COMBO')) {
      return 'assets/icons/marketing.png';
    }
    if (code.contains('REVIEW') || name.contains('REVIEW')) {
      return 'assets/icons/review.png';
    }
    if (code.contains('RATING') || name.contains('RATING') || name.contains('STAR')) {
      return 'assets/icons/rating.png';
    }
    if (code.contains('COMMENT') || name.contains('COMMENT')) {
      return 'assets/icons/comment.png';
    }
    if (code.contains('SUB') || name.contains('SUB') || name.contains('SUBSCRIBE')) {
      return 'assets/icons/subscribe.png';
    }
    if (code.contains('FOLLOW') || name.contains('FOLLOW')) {
      return 'assets/icons/instagram.png';
    }
    if (code.contains('LIKE') || name.contains('LIKE')) {
      return 'assets/icons/like.png';
    }
    if (code.contains('INSTALL') ||
        name.contains('INSTALL') ||
        code.contains('DOWNLOAD') ||
        name.contains('DOWNLOAD')) {
      return 'assets/icons/smartphone.png';
    }
    if (code.contains('PLAY') ||
        code.contains('WATCH') ||
        name.contains('WATCH') ||
        name.contains('VIEW')) {
      return 'assets/icons/play.png';
    }
    // Category-level fallbacks if no specific sub-type matched
    if (code.contains('PLAY') || code.contains('GOOGLE')) {
      return 'assets/icons/google-play.png';
    }
    if (code.contains('YT') || code.contains('YOUTUBE')) {
      return 'assets/icons/youtube.png';
    }
    if (code.contains('INSTA') || code.contains('IG')) {
      return 'assets/icons/instagram.png';
    }
    return null;
  }

  // ── Icon Resolver for Sub-Services (Vector Fallback) ──
  IconData _getServiceSubIcon(ServiceModel s) {
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    // Check COMBO first so combo services never get mistaken for single sub/like
    if (code.contains('COMBO') || name.contains('COMBO')) {
      return Icons.auto_awesome_rounded;
    }
    if (code.contains('REVIEW')) return Icons.rate_review_rounded;
    if (code.contains('RATING')) return Icons.star_rounded;
    if (code.contains('COMMENT') || name.contains('COMMENT')) {
      return Icons.chat_bubble_rounded;
    }
    if (code.contains('SUB') || code.contains('LIKE') || name.contains('SUB')) {
      return Icons.notifications_active_rounded;
    }
    if (code.contains('FOLLOW') || name.contains('FOLLOW')) {
      return Icons.person_add_alt_1_rounded;
    }
    if (code.contains('INSTALL') || name.contains('INSTALL')) {
      return Icons.install_mobile_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  // ── Full Detailed Info for "i" Info Modal ──
  Map<String, dynamic> _getServiceFullInfo(ServiceModel s) {
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final isAi = s.aiGeneratorEnabled;

    // ── Instagram Services ──
    if (code.contains('INSTA') || name.contains('INSTA') || s.category.toUpperCase().contains('INSTA')) {
      if (code.contains('COMBO') || name.contains('COMBO')) {
        return {
          'badge': '🔥 2-IN-1 INSTAGRAM GROWTH COMBO',
          'overview':
              'Dual-action profile accelerator: Real active users follow your Instagram profile and like your latest post or reel from authentic mobile devices.',
          'features': [
            '👤 1 Real Profile Follower Included',
            '❤️ 1 Genuine Post / Reel Like Included',
            '⚡ Rapidly Boosts Explore & Reel Recommendations',
            '100% Real Active Mobile Device Accounts',
            'Permanent Non-Drop Protection',
          ],
        };
      }

      if (code.contains('COMMENT') || name.contains('COMMENT')) {
        return {
          'badge': '🤖 VIRAL RELEVANT COMMENTS',
          'overview':
              'Contextual, natural comments matching your exact post content or niche. Real users post them from personal accounts to stimulate discussion and algorithmic reach.',
          'features': [
            'Topic-Relevant Natural Human Comments',
            'Custom Tone & Language Options',
            'Boosts Post Comment Velocity & Explore Ranking',
            'Active Verified Instagram Users',
            'Permanent Non-Drop Guarantee',
          ],
        };
      }

      if (code.contains('LIKE') || name.contains('LIKE')) {
        return {
          'badge': '⚡ INSTANT EXPLORE BOOST',
          'overview':
              'Real Instagram users like your photo, carousel, or reel. High initial engagement velocity signals strong audience interest to Instagram explore recommendations.',
          'features': [
            'Instant Delivery & High Daily Capacity',
            'Supports Photos, Carousels & Reels',
            'Safe for Personal & Brand Accounts',
            '100% Real Human Profiles',
            'Permanent Non-Drop Protection',
          ],
        };
      }

      if (code.contains('FOLLOW') || name.contains('FOLLOW')) {
        return {
          'badge': '🔥 PROFILE REACH & AUTHORITY',
          'overview':
              'Real active human profiles follow your Instagram account. Helps establish instant social proof, unlocks brand credibility, and enhances your profile search ranking.',
          'features': [
            '100% Genuine Active Profiles',
            'High-Retention Non-Drop Protection',
            'Builds Permanent Brand Authority',
            'Safe & Organic Delivery Pacing',
          ],
        };
      }
    }

    if (code.contains('REVIEW') ||
        (name.contains('REVIEW') && name.contains('RATING')) ||
        (isAi && (code.contains('PLAY') || name.contains('PLAY')))) {
      return {
        'badge': '👑 RECOMMENDED FOR ASO',
        'overview':
            'Real human users download your app on personal Android phones, test it for 30s+, give a genuine 5-star rating, and post authentic review text. Directly improves Google Play Store keyword search ranking.',
        'features': [
          'Authentic 5-Star Rating + Full Review Text',
          'Natural Human Reviews & Comments',
          'Direct Google Play Store ASO Keyword Boost',
          '100% Real Physical Android Smartphones',
          'Permanent Non-Drop Anti-Spam Guarantee',
        ],
      };
    }

    if (code.contains('RATING') ||
        name.contains('RATING (ONLY)') ||
        name.contains('RATING ONLY') ||
        (!isAi && (code.contains('PLAY') || name.contains('PLAY')))) {
      return {
        'badge': '⚡ FASTEST STAR LIFT',
        'overview':
            'Real users open your app on Google Play Store and give an instant 5-star rating without text comments. Best for rapidly lifting your overall star score at a budget-friendly rate.',
        'features': [
          'Direct 5-Star Rating (No text required)',
          'Super Fast Turnaround & High Daily Capacity',
          'Lower Cost Per Rating (Maximum Cost Efficiency)',
          'Real Verified Google Accounts',
          'Permanent Non-Drop Protection',
        ],
      };
    }

    if ((code.contains('YT') || code.contains('YOUTUBE') || s.category.toUpperCase().contains('YOUTUBE')) &&
        (code.contains('COMBO') || name.contains('COMBO'))) {
      return {
        'badge': '🚀 4-IN-1 ALL-IN-ONE VIRAL BUNDLE',
        'overview':
            'Complete YouTube viral package: Every worker watches your video (duration-synced up to 5 min), likes the video, subscribes to your channel, and posts a relevant contextual AI comment.',
        'features': [
          '⏱️ Video Watch Time (Full video up to 5 min)',
          '👍 Genuine Thumbs-Up Like on Video',
          '🔔 Permanent Channel Subscription',
          '💬 Relevant Contextual AI Comment',
          '⚡ Triggers YouTube Browse & Suggested Recommendations',
          '100% Real Active Google / YouTube Accounts',
        ],
      };
    }

    if (code.contains('COMMENT') || name.contains('COMMENT')) {
      return {
        'badge': '🎯 ALGORITHM ENGAGEMENT',
        'overview':
            'Real viewers watch your YouTube video for at least 30 seconds and post contextual, human-like comments. Signals high viewer interest to YouTube recommendation algorithms to boost impressions.',
        'features': [
          'Minimum 30 Seconds Watch Time Included',
          'Topic-Relevant Natural Comments',
          'Triggers YouTube Suggestion & Recommended Feeds',
          'Verified Active Google/YouTube Accounts',
        ],
      };
    }

    if (code.contains('SUB') ||
        code.contains('LIKE') ||
        name.contains('SUB') ||
        name.contains('LIKE')) {
      return {
        'badge': '📈 CHANNEL GROWTH',
        'overview':
            'Real users subscribe to your channel and turn on notifications. Helps unlock YouTube Partner Program monetization milestones and creates permanent social proof.',
        'features': [
          '100% Genuine Human Subscribers',
          'High Retention Non-Drop Guarantee',
          'Helps Reach Partner Program Milestones',
          'Steady, Safe & Organic Delivery Pacing',
        ],
      };
    }

    if (code.contains('INSTALL') || name.contains('INSTALL')) {
      return {
        'badge': '📊 STORE DOWNLOADS',
        'overview':
            'Real users search, download, install, and open your application on their personal Android devices for at least 30 seconds. Directly improves Google Play Store install metrics and trending rank.',
        'features': [
          'Verified Physical Android Phone Installs',
          'Active 30-Second In-App Testing Session',
          'Increases Store Trending Ranking',
          'Unique IP & Hardware Device IDs',
        ],
      };
    }

    return {
      'badge': '⭐ VERIFIED QUALITY',
      'overview': s.description.isNotEmpty
          ? s.description
          : 'High-quality promotional delivery performed by real users on personal mobile devices with automated verification.',
      'features': [
        '100% Genuine Human Actions',
        'Real-Time Tracking & Verification',
        'Guaranteed Delivery or Refund',
        'Platform Safe & Compliant',
      ],
    };
  }

  // ── Show "i" Detailed Info Modal Bottom Sheet (Light & Clean) ──
  void _showServiceInfoSheet(BuildContext context, ServiceModel service) {
    final info = _getServiceFullInfo(service);
    final icon = _getServiceSubIcon(service);
    final serviceAsset = _getServiceAssetIcon(service);
    final badge = info['badge'] as String;
    final overview = info['overview'] as String;
    final features = info['features'] as List<String>;
    final price = service.pricing.buyerPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: _palette.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
              const BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Icon + Title + Close
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _palette.cardBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _palette.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: serviceAsset != null
                        ? Image.asset(
                            serviceAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              icon,
                              color: _palette.primaryDeep,
                              size: 24,
                            ),
                          )
                        : Icon(
                            icon,
                            color: _palette.primaryDeep,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _palette.iconBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _palette.cardBorder, width: 0.8),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _palette.primaryDeep,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF94A3B8), size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rate Banner (Inside modal!)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _palette.iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _palette.cardBorder, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price per ${ServiceUnitHelper.getUnitName(service.name, count: 1)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ServiceUnitHelper.getRateLabel(service.name, price),
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: _palette.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Section
              Text(
                'About this Service',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                overview,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),

              // Key Features
              Text(
                'Key Benefits & Guarantees',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 15, color: _palette.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feat,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),

              // Select Service Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSelectService(service);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_palette.selectBtnStart, _palette.selectBtnEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _palette.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select This Service & Continue',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeServices = widget.services.where((s) => s.isActive).toList();
    if (activeServices.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. INDEPENDENT CATEGORY HEADER CARD ──
        Container(
          margin: EdgeInsets.only(bottom: _isExpanded ? 8 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_palette.cardBgStart, _palette.cardBgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded ? _palette.primaryLight : _palette.cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _palette.primary
                    .withValues(alpha: _isExpanded ? 0.08 : 0.04),
                blurRadius: _isExpanded ? 12 : 8,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Color(0x05000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggleExpand,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Category Icon Avatar (Asset PNG if available, fallback to IconData)
                    Builder(
                      builder: (context) {
                        final catAsset =
                            _getCategoryAssetIcon(widget.categoryName);
                        if (catAsset != null) {
                          return Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: _palette.cardBorder,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _palette.primary.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(7),
                            child: Image.asset(
                              catAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                widget.icon,
                                color: _palette.primaryDeep,
                                size: 20,
                              ),
                            ),
                          );
                        }
                        return Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _palette.primaryLight,
                                _palette.primaryDeep
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    _palette.primary.withValues(alpha: 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child:
                                Icon(widget.icon, color: Colors.white, size: 20),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),

                    // Category Name (Compact font, visible completely at one time)
                    Expanded(
                      child: Text(
                        widget.categoryName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clean Chevron
                    RotationTransition(
                      turns: _chevronRotation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color:
                            _isExpanded ? _palette.primaryDeep : textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 2. INDEPENDENT SERVICE CARDS (EXPANDED OUTSIDE THE CATEGORY CARD) ──
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
            child: Column(
              children: activeServices.map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCleanSubCard(context, service),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── INDEPENDENT SUB-SERVICE CARD (STANDALONE CARD ON WHITE SCREEN) ──
  Widget _buildCleanSubCard(BuildContext context, ServiceModel service) {
    final icon = _getServiceSubIcon(service);
    final serviceAsset = _getServiceAssetIcon(service);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_palette.subCardBgStart, _palette.subCardBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _palette.cardBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: _palette.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Icon + Compact Title (visible at one glance) + "i" Info Button ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mini Icon Box with Real Asset Icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _palette.cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _palette.primary.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: serviceAsset != null
                    ? Image.asset(
                        serviceAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          icon,
                          color: _palette.primaryDeep,
                          size: 18,
                        ),
                      )
                    : Icon(
                        icon,
                        color: _palette.primaryDeep,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 10),

              // Title: Compact font (12.5px), visible completely at one glance ("one time me dikha")
              Expanded(
                child: Text(
                  service.name,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    height: 1.25,
                    letterSpacing: 0.05,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // ℹ️ "i" Info Button (Opens rate & complete details bottom sheet)
              GestureDetector(
                onTap: () => _showServiceInfoSheet(context, service),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _palette.iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _palette.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _palette.primaryDeep,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          // ── Dedicated Combo Inclusions Pill (Highlights Watch + Like + Sub + Comment) ──
          if (service.code.toUpperCase().contains('COMBO') || service.name.toUpperCase().contains('COMBO')) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (service.code.toUpperCase().contains('YT') || service.name.toUpperCase().contains('YT') || service.category.toUpperCase().contains('YOUTUBE'))
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (service.code.toUpperCase().contains('YT') || service.name.toUpperCase().contains('YT') || service.category.toUpperCase().contains('YOUTUBE'))
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFFBCFE8),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 11,
                    color: (service.code.toUpperCase().contains('YT') || service.name.toUpperCase().contains('YT') || service.category.toUpperCase().contains('YOUTUBE'))
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFDB2777),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      (service.code.toUpperCase().contains('YT') || service.name.toUpperCase().contains('YT') || service.category.toUpperCase().contains('YOUTUBE'))
                          ? 'Includes: Watch Time + Like + Subscribe + Comment'
                          : 'Includes: Profile Follow + Post/Reel Like',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (service.code.toUpperCase().contains('YT') || service.name.toUpperCase().contains('YT') || service.category.toUpperCase().contains('YOUTUBE'))
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF9D174D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ── Row 2: Rate Badge on Left + Clean Select Button Aligned Right ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price badge with unit: e.g. "₹8.00 / combo" or "₹2.00 / subscriber"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: (service.code.toUpperCase().contains('COMBO') || service.name.toUpperCase().contains('COMBO'))
                      ? const Color(0xFFEFF6FF)
                      : _palette.iconBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: (service.code.toUpperCase().contains('COMBO') || service.name.toUpperCase().contains('COMBO'))
                        ? const Color(0xFFBFDBFE)
                        : _palette.cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  ServiceUnitHelper.getRateLabel(service.name, service.pricing.buyerPrice),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: (service.code.toUpperCase().contains('COMBO') || service.name.toUpperCase().contains('COMBO'))
                        ? const Color(0xFF1D4ED8)
                        : _palette.primaryDeep,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onSelectService(service),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_palette.selectBtnStart, _palette.selectBtnEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _palette.primary.withValues(alpha: 0.22),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 11),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
