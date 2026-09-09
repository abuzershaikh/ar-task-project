import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/domain/models/service_model.dart';
import '../../../services/data/repositories/service_repository_impl.dart';
import '../../../services/presentation/widgets/category_accordion_card.dart';
import '../../../services/presentation/widgets/ai_comment_config_widget.dart';
import '../../../../core/utils/service_unit_helper.dart';

class CreateCampaignPage extends StatefulWidget {
  final String? serviceId;

  const CreateCampaignPage({super.key, this.serviceId});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final ServiceRepositoryImpl _serviceRepository = ServiceRepositoryImpl();

  List<ServiceModel> _publishedServices = [];
  ServiceModel? _selectedService;
  bool _isLoading = true;
  double _walletBalance = 0.0;

  // Order Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _targetUrlController = TextEditingController();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '10');
  int _selectedQuantity = 10;
  String _selectedLanguage = 'English';
  String _selectedTone = 'natural';
  bool _isSubmitting = false;
  List<String> _sampleComments = [];
  bool _isGeneratingPreview = false;

  // Play Store App Metadata State
  String? _appName;
  String? _appIcon;
  String? _packageId;
  bool _isFetchingAppInfo = false;
  String? _appFetchError;
  Timer? _urlDebounceTimer;

  // YouTube Video Metadata State
  String? _ytTitle;
  String? _ytThumbnail;
  int? _ytDurationSeconds;
  int? _ytRequiredWatchSeconds;
  String? _ytDurationFormatted;
  String? _ytRequiredWatchFormatted;
  bool _ytIsCappedAt5Min = false;
  bool _isFetchingYtInfo = false;
  String? _ytFetchError;

  @override
  void initState() {
    super.initState();
    _loadPublishedServices();
    _loadWalletBalance();
  }

  @override
  void dispose() {
    _urlDebounceTimer?.cancel();
    _targetUrlController.dispose();
    _appNameController.dispose();
    _topicController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  bool _isPlayStoreService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();
    return code.contains('PLAY') ||
        code.contains('REVIEW') ||
        code.contains('RATING') ||
        cat.contains('PLAY') ||
        name.contains('PLAY') ||
        name.contains('REVIEW') ||
        desc.contains('PLAY STORE');
  }

  bool _isYouTubeService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();
    return code.contains('YOUTUBE') ||
        code.contains('YT_') ||
        cat.contains('YOUTUBE') ||
        name.contains('YOUTUBE') ||
        desc.contains('YOUTUBE');
  }

  void _onTargetUrlChanged(String val) {
    final trimmed = val.trim();
    final isPlayStore = _isPlayStoreService(_selectedService);
    final isYouTube = _isYouTubeService(_selectedService) ||
        trimmed.contains('youtube.com') ||
        trimmed.contains('youtu.be');

    if (!isPlayStore && !isYouTube) return;
    _urlDebounceTimer?.cancel();

    if (trimmed.isEmpty) {
      setState(() {
        _appName = null;
        _appNameController.clear();
        _appIcon = null;
        _packageId = null;
        _appFetchError = null;
        _isFetchingAppInfo = false;

        _ytTitle = null;
        _ytThumbnail = null;
        _ytDurationSeconds = null;
        _ytRequiredWatchSeconds = null;
        _ytDurationFormatted = null;
        _ytRequiredWatchFormatted = null;
        _ytIsCappedAt5Min = false;
        _ytFetchError = null;
        _isFetchingYtInfo = false;

        _sampleComments = [];
      });
      return;
    }

    if (isPlayStore) {
      if (_appFetchError != null) setState(() => _appFetchError = null);
      if (trimmed.length >= 5 && (trimmed.contains('.') || trimmed.contains('/'))) {
        setState(() {
          _appIcon = null;
          _packageId = null;
        });
        _urlDebounceTimer = Timer(const Duration(milliseconds: 700), () {
          _fetchPlayStoreAppInfo(trimmed);
        });
      }
    } else if (isYouTube) {
      if (_ytFetchError != null) setState(() => _ytFetchError = null);
      if (trimmed.length >= 10 && (trimmed.contains('youtu.be') || trimmed.contains('youtube.com'))) {
        _urlDebounceTimer = Timer(const Duration(milliseconds: 600), () {
          _fetchYouTubeVideoInfo(trimmed);
        });
      }
    }
  }

  Future<void> _fetchYouTubeVideoInfo(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || _serviceRepository.dioClient == null) return;
    setState(() {
      _isFetchingYtInfo = true;
      _ytFetchError = null;
    });

    try {
      final res = await _serviceRepository.dioClient!.post(
        '/buyer/orders/youtube-video-info',
        data: {'url': trimmed},
      );

      final isSuccess = (res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null &&
          res.data['success'] == true;

      if (isSuccess) {
        final data = res.data;
        setState(() {
          _ytTitle = data['title']?.toString();
          _ytThumbnail = data['thumbnail']?.toString();
          _ytDurationSeconds = data['durationSeconds'] is int
              ? data['durationSeconds']
              : int.tryParse(data['durationSeconds']?.toString() ?? '0');
          _ytRequiredWatchSeconds = data['requiredWatchSeconds'] is int
              ? data['requiredWatchSeconds']
              : int.tryParse(data['requiredWatchSeconds']?.toString() ?? '0');
          _ytDurationFormatted = data['durationFormatted']?.toString();
          _ytRequiredWatchFormatted = data['requiredWatchFormatted']?.toString();
          _ytIsCappedAt5Min = data['isCappedAt5Min'] == true;
          _ytFetchError = null;

          if (_ytTitle != null && _ytTitle!.isNotEmpty) {
            _appName = _ytTitle;
            _appNameController.text = _ytTitle!;
          }
        });
      } else {
        final err = res.data?['error']?.toString();
        setState(() {
          _ytFetchError = err ?? 'Could not extract video duration from YouTube link.';
        });
      }
    } catch (err) {
      debugPrint('Error fetching YouTube metadata: $err');
      setState(() {
        _ytFetchError = 'Could not fetch video info. You can still proceed normally.';
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingYtInfo = false);
      }
    }
  }

  Future<void> _fetchPlayStoreAppInfo(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || _serviceRepository.dioClient == null) return;
    setState(() {
      _isFetchingAppInfo = true;
      _appFetchError = null;
    });

    try {
      final res = await _serviceRepository.dioClient!.post(
        '/buyer/orders/playstore-app-info',
        data: {'url': trimmed},
      );

      final isSuccess = (res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null &&
          res.data['success'] == true;

      if (isSuccess) {
        final data = res.data;
        setState(() {
          _appIcon = data['appIcon']?.toString();
          _packageId = data['packageId']?.toString();
          final rawName = data['appName']?.toString();
          if (rawName != null && rawName.isNotEmpty) {
            final cleanName = rawName.split(RegExp(r'[:\-|–—•(]'))[0].trim();
            _appName = cleanName;
            _appNameController.text = cleanName;
          }
          _appFetchError = null;
          // Reset sample comments so user generates explicitly via the "Generate" button
          _sampleComments = [];
        });
      } else {
        final err = res.data?['error']?.toString();
        setState(() {
          _appFetchError = (err != null && err.isNotEmpty)
              ? err
              : 'App metadata not found on Google Play Store. Please check the link or package name.';
        });
      }
    } catch (err) {
      debugPrint('Error fetching Play Store metadata: $err');
      setState(() {
        _appFetchError = 'Could not fetch app info. You can still proceed normally.';
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingAppInfo = false);
      }
    }
  }

  bool _isCommentOrComboService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    // Instagram combo is strictly Like + Follow, NOT comment!
    if (code.contains('INSTA') && (code.contains('COMBO') || code.contains('FOLLOW') || code.contains('LIKE'))) {
      if (!code.contains('COMMENT')) return false;
    }
    // YouTube Combo IS a comment service (Watch + Like + Sub + Comment)
    if ((code.contains('YT') || code.contains('YOUTUBE')) && code.contains('COMBO')) {
      return true;
    }
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final type = s.serviceType.toUpperCase();
    return s.aiGeneratorEnabled ||
        code.contains('COMMENT') ||
        code.contains('REVIEW') ||
        name.contains('COMMENT') ||
        name.contains('REVIEW') ||
        desc.contains('COMMENT') ||
        type.contains('COMMENT');
  }

  Future<void> _generateSampleComments() async {
    setState(() => _isGeneratingPreview = true);
    final userAppName = _appNameController.text.trim().isNotEmpty
        ? _appNameController.text.trim()
        : (_isYouTubeService(_selectedService) ? (_ytTitle ?? '') : (_appName ?? ''));
    final cleanBrand = userAppName.split(RegExp(r'[:\-|–—•(]'))[0].trim();
    final userPrompt = _topicController.text.trim();

    try {
      if (_serviceRepository.dioClient != null) {
        try {
          final res = await _serviceRepository.dioClient!.post(
            '/buyer/orders/ai-preview-comments',
            data: {
              'topic': userPrompt,
              'prompt': userPrompt,
              'language': _selectedLanguage,
              'tone': _selectedTone,
              'count': _selectedQuantity,
              'serviceCode': _selectedService?.code,
              'targetUrl': _targetUrlController.text.trim(),
              'appName': cleanBrand,
              'videoTitle': _isYouTubeService(_selectedService) ? (_ytTitle?.isNotEmpty == true ? _ytTitle! : userAppName) : '',
            },
          );
          if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null && res.data['sampleComments'] != null) {
            final List comments = res.data['sampleComments'];
            if (comments.isNotEmpty) {
              setState(() {
                _sampleComments = comments
                    .map((c) => _sanitizeCommentText(c.toString()))
                    .where((c) => c.isNotEmpty)
                    .toList();
              });
              return;
            }
          }
        } catch (apiErr) {
          debugPrint('Preview API error, fallback: $apiErr');
        }
      }

      // Instant Organic Fallback Generation with Semantic Intent Matching
      final targetCount = _selectedQuantity < 5 ? (_selectedQuantity > 0 ? _selectedQuantity : 1) : 5;
      final isReview = _selectedService?.code.toUpperCase().contains('PLAY') == true ||
          _selectedService?.code.toUpperCase().contains('REVIEW') == true ||
          _selectedService?.category.toUpperCase().contains('PLAY') == true ||
          _selectedService?.name.toUpperCase().contains('PLAY') == true ||
          _selectedService?.name.toUpperCase().contains('REVIEW') == true;

      final isHindi = _selectedLanguage.toLowerCase().contains('hindi') || _selectedLanguage.toLowerCase().contains('hinglish');
      final lowerPrompt = userPrompt.toLowerCase();

      final isPart2 = RegExp(r'part\s*2|part\s*two|next\s*part|next\s*video|sequel|agla\s*part|doosra\s*part|part2', caseSensitive: false).hasMatch(lowerPrompt);
      final isAudio = RegExp(r'audio|mic|voice|sound|clarity|awaz|aawaz|noise', caseSensitive: false).hasMatch(lowerPrompt);
      final isTrading = RegExp(r'trading|stock|market|crypto|forex|chart|candle|indicator|profit', caseSensitive: false).hasMatch(lowerPrompt);
      final isTutorial = RegExp(r'explain|tutorial|guide|sikha|samjh|concept|sikhao|trick', caseSensitive: false).hasMatch(lowerPrompt);
      final isPayment = RegExp(r'pay|upi|money|transaction|wallet|paisa|cash|billing', caseSensitive: false).hasMatch(lowerPrompt);
      final isDelivery = RegExp(r'deliver|pickup|speed|fast|doorstep|service|courier', caseSensitive: false).hasMatch(lowerPrompt);
      final isUi = RegExp(r'ui|design|interface|clean|navigation|simple|layout', caseSensitive: false).hasMatch(lowerPrompt);
      final isSupport = RegExp(r'support|help|service|care|team|contact', caseSensitive: false).hasMatch(lowerPrompt);

      // Extract clean subject from video title or prompt
      String subject = cleanBrand.isNotEmpty ? cleanBrand : userPrompt;
      subject = subject
          .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\[\(][^\]\)]*(?:official|music|video|4k|hd|1080p|full|ep\s*\d+|part\s*\d+)[^\]\)]*[\]\)]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\|\s*[^|]+$'), '')
          .replaceAll(RegExp(r'[-–—]\s*[^–—]+$'), '')
          .replaceAll(RegExp(r'#\w+'), '')
          .replaceAll(RegExp(r'\b(202[0-9]|hindi|urdu|english|full\s*video|watch\s*now)\b', caseSensitive: false), '')
          .trim();
      if (subject.contains(':')) subject = subject.split(':')[0].trim();
      if (subject.isEmpty) subject = 'is video';

      List<String> fallbacks = [];

      if (isReview) {
        if (isPayment) {
          fallbacks = isHindi
              ? [
                  "Payment process ekdum instant aur secure hai, wallet me turant reflect hota hai.",
                  "Transactions super fast hain aur koi deduction error nahi aata, very reliable.",
                  cleanBrand.isNotEmpty ? "$cleanBrand me payment bohot smooth hai, trustworthy app." : "Bohot safe aur dependable payment system mila mujhe.",
                ]
              : [
                  "Instant and reliable payment processing, haven't faced a single glitch.",
                  "Transactions are super quick and secure, very transparent billing.",
                  cleanBrand.isNotEmpty ? "Payments on $cleanBrand are seamless and instantaneous." : "Very safe checkout experience with fast transactions.",
                ];
        } else if (isDelivery) {
          fallbacks = isHindi
              ? [
                  "Doorstep pickup aur service timing bohot fast aur punctual hai.",
                  "Bohot jaldi pickup ho gaya, staff ka behavior bhi kaafi polite tha.",
                  cleanBrand.isNotEmpty ? "$cleanBrand ki doorstep service ekdum fast hai." : "Quick and punctual execution, completely hassle-free.",
                ]
              : [
                  "Doorstep pickup and handling was remarkably fast and punctual.",
                  "Order fulfillment and quick response exceeded my expectations.",
                  cleanBrand.isNotEmpty ? "The pickup service from $cleanBrand was swift and professional." : "Extremely fast service, completed well ahead of schedule.",
                ];
        } else if (isUi) {
          fallbacks = isHindi
              ? [
                  "UI bohot clean aur modern hai, navigation ekdum smooth hai.",
                  "Sabhi features aasan hain, koi bhi bina confuse hue chala sakta hai.",
                  cleanBrand.isNotEmpty ? "$cleanBrand ka interface kaafi lightweight aur stylish hai." : "Bohot pyara design hai, har option seedha samajh aata hai.",
                ]
              : [
                  "The user interface is sleek, modern, and clutter-free.",
                  "Clean design and fluid page transitions, truly top tier UI.",
                  cleanBrand.isNotEmpty ? "Navigating $cleanBrand is effortless and intuitive." : "Minimalist layout that makes daily tasks enjoyable.",
                ];
        } else if (isSupport) {
          fallbacks = isHindi
              ? [
                  "Customer support ne turant meri query resolve kar di, bohot helpful team hai.",
                  "Help center ka response time kaafi fast hai, polite behavior.",
                  cleanBrand.isNotEmpty ? "$cleanBrand support team genuinely listens and helps out." : "Very prompt customer assistance, super happy with the response.",
                ]
              : [
                  "Customer support was very prompt and resolved my query in minutes.",
                  "Help desk is super responsive, polite, and genuinely helpful.",
                  cleanBrand.isNotEmpty ? "The support team behind $cleanBrand is outstanding." : "Quick resolution from support, very dependable assistance.",
                ];
        } else {
          fallbacks = isHindi
              ? [
                  cleanBrand.isNotEmpty ? "$cleanBrand use karke maza aa gaya, UI ekdum smooth aur fast hai." : "Bohot hi smooth chal raha hai, UI ekdum clean aur fast hai.",
                  "Kamaal ka application hai, use karna bohot aasan aur convenient hai.",
                  cleanBrand.isNotEmpty ? "$cleanBrand ne kaam bohot aasan bana diya hai, sabhi features acche se chal rahe hain." : "Bohot accha user experience mila, bilkul lag nahi karta.",
                  "Shaandar design aur super fast speed hai, daily use ke liye best app hai.",
                  cleanBrand.isNotEmpty ? "Maine $cleanBrand use kiya aur experience kaafi badhiya raha. Highly recommended." : "Abhi tak ka sabse best app laga mujhe is category me. Bohot helpful hai.",
                ]
              : [
                  cleanBrand.isNotEmpty ? "Using $cleanBrand has been a great experience. Very smooth and reliable." : "Very smooth and responsive app. Does exactly what it promises without clutter.",
                  "Clean UI and great user experience. Everything works seamlessly right from the start.",
                  cleanBrand.isNotEmpty ? "$cleanBrand makes everyday tasks so much easier and convenient." : "Super fast, lightweight and intuitive. Very happy with the overall performance.",
                  "Simple, clean, and gets the job done quickly. Exactly what I was looking for.",
                  cleanBrand.isNotEmpty ? "Really glad I installed $cleanBrand. Fast responses and zero lag." : "One of the best apps in this category. Works like a charm and saves me so much time.",
                ];
        }
      } else {
        // YouTube / Social Video Comments (Contextual with Subject & Video Title)
        if (isPart2) {
          fallbacks = isHindi
              ? [
                  "Bhai iska Part 2 kab aayega? Jaldi upload karo please!",
                  "$subject ka next part besabri se wait kar raha hu, bohot zabardast explanation tha.",
                  "Bhai agla part zaroor lana, aage ka concept bhi detail me dekhna hai!",
                  "$subject ka Part 2 jaldi lao bhai, poora topic complete dekhna hai!",
                  "Subscribed! Please agla part jaldi drop karna bhai, can't wait!",
                ]
              : [
                  "Really hope there is a Part 2 coming out soon! Left me wanting more.",
                  "Can you please drop Part 2 on $subject as soon as possible? Super excited!",
                  "Waiting eagerly for part 2, this explanation was crystal clear.",
                  "Bro we need Part 2 on this immediately, loved the breakdown of $subject!",
                  "Subscribed just for Part 2! Please do not keep us waiting too long.",
                ];
        } else if (isAudio) {
          fallbacks = isHindi
              ? [
                  "Bhai audio quality ekdum crystal clear hai, sunne me maza aa gaya.",
                  "Aapki voice clarity aur sound setup bohot badhiya hai bhai.",
                  "Ekdum saaf aawaz hai, har ek point clearly samajh aaya.",
                  "Mic quality aur explanation dono top tier hain bhai!",
                ]
              : [
                  "The audio quality and mic clarity are top notch, super easy to listen to.",
                  "Loved the clear sound quality and voiceover, made following along effortless.",
                  "Voice clarity is 10/10 in this video, great production quality!",
                  "Super crisp audio! Really appreciate creators who care about clear sound.",
                ];
        } else if (isTrading) {
          fallbacks = isHindi
              ? [
                  "$subject ka market setup aur risk management bohot practical bataya aapne!",
                  "Chart reading aur price action ka tareeka ekdum accurate hai bhai, taking notes!",
                  "$subject sikhne ke liye sabse best aur disciplined video hai ye.",
                  "Aapka chart reading aur SL lagane ka tareeka bohot safe hai, shukriya bhai!",
                ]
              : [
                  "The risk management and chart strategy explained for $subject are top notch!",
                  "Super insightful breakdown of $subject, price action analysis was on point.",
                  "Best trading breakdown I have watched this month, super practical insights.",
                  "Clear price action analysis without confusing indicators, loved it!",
                ];
        } else if (isTutorial) {
          fallbacks = isHindi
              ? [
                  "$subject ko itne simple tareeke se samjhaya aapne, poora doubt clear ho gaya.",
                  "Point to point baat ki hai $subject par bina time waste kiye, bohot helpful raha.",
                  "Aapka samjhane ka tareeka sabse best hai bhai, ek baar me $subject clear ho gaya.",
                  "Bohot informative aur valuable guide on $subject, shukriya bhai!",
                ]
              : [
                  "The step-by-step breakdown of $subject was so clean and easy to follow.",
                  "Finally someone who explains $subject straight to the point without wasting time.",
                  "This cleared up so much confusion regarding $subject, thanks for sharing!",
                  "One of the best tutorials on $subject on YouTube, bookmarked!",
                ];
        } else {
          fallbacks = isHindi
              ? [
                  "$subject ke baare me bohot hi aasan aur saral tareeke se samjhaya aapne bhai!",
                  "$subject par bohot saare doubts the mere, is video ke baad sab clear ho gaya.",
                  "Aapka $subject ka breakdown bohot informative aur valuable raha, full support bhai!",
                  "Seedha point to point baat ki hai $subject par bina time waste kiye, keep it up!",
                  "$subject sikhne ke liye YouTube par sabse best video hai ye, maza aa gaya dekh kar.",
                  "Content quality top class hai bhai, $subject par aur bhi videos banate rahiye!",
                ]
              : [
                  "The way you explained $subject was exceptionally clear and easy to follow!",
                  "This cleared up all my confusion regarding $subject, really appreciate the depth!",
                  "Straight to the point with zero fluff, one of the best videos on $subject.",
                  "Super informative and actionable breakdown of $subject, keep up the great work!",
                  "Genuinely one of the most well-structured guides on $subject out there, bookmarked!",
                  "Appreciate the effort and depth put into this video on $subject, highly valuable!",
                ];
        }
      }

      setState(() {
        _sampleComments = fallbacks.map((f) => _sanitizeCommentText(f)).take(targetCount).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate sample preview: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPreview = false);
      }
    }
  }

  String _sanitizeCommentText(String text) {
    return text
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}⭐★🌟✨🌠🎖️🏅🏆💯🔥👍👎]', unicode: true), '')
        .replaceAll(RegExp(r'\b5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5\s*\/\s*5\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfive\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5-star\s*(rating)?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfull\s*5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+([.,!?])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  Future<void> _loadWalletBalance() async {
    try {
      if (_serviceRepository.dioClient != null) {
        final res = await _serviceRepository.dioClient!.get('/buyer/wallet/balance');
        if (res.statusCode == 200 && res.data != null) {
          final bal = res.data['balance'];
          if (bal != null && bal['available'] != null) {
            if (mounted) {
              setState(() {
                _walletBalance = (bal['available'] as num).toDouble();
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPublishedServices() async {
    setState(() => _isLoading = true);
    final services = await _serviceRepository.getPublishedServices();
    setState(() {
      _publishedServices = services;
      _isLoading = false;

      if (widget.serviceId != null) {
        try {
          _selectService(services.firstWhere((s) => s.id == widget.serviceId));
        } catch (_) {}
      }
    });
  }

  void _selectService(ServiceModel service) {
    _urlDebounceTimer?.cancel();
    setState(() {
      _selectedService = service;
      _selectedQuantity = 10;
      _quantityController.text = '10';
      _targetUrlController.clear();
      _appNameController.clear();
      _topicController.clear();
      _sampleComments = [];
      _appName = null;
      _appIcon = null;
      _packageId = null;
      _appFetchError = null;
      _isFetchingAppInfo = false;

      _ytTitle = null;
      _ytThumbnail = null;
      _ytDurationSeconds = null;
      _ytRequiredWatchSeconds = null;
      _ytDurationFormatted = null;
      _ytRequiredWatchFormatted = null;
      _ytIsCappedAt5Min = false;
      _ytFetchError = null;
      _isFetchingYtInfo = false;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() {
        _targetUrlController.text = data.text!.trim();
      });
      if (_isPlayStoreService(_selectedService)) {
        _fetchPlayStoreAppInfo(_targetUrlController.text.trim());
      } else if (_isYouTubeService(_selectedService) ||
          _targetUrlController.text.contains('youtube.com') ||
          _targetUrlController.text.contains('youtu.be')) {
        _fetchYouTubeVideoInfo(_targetUrlController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Link pasted from clipboard'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            duration: Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _calculateTotalCost() {
    if (_selectedService == null) return 0.0;
    return _selectedQuantity * _selectedService!.pricing.buyerPrice;
  }

  void _submitCampaign() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final totalCost = _calculateTotalCost();
    if (_walletBalance < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Insufficient wallet balance (₹${_walletBalance.toStringAsFixed(2)}). Required: ₹${totalCost.toStringAsFixed(2)}. Please top up!'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isCommentService = _isCommentOrComboService(_selectedService);

    if (isCommentService && _sampleComments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Please generate sample comments first before placing the order!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderPayload = {
        'serviceCode': _selectedService!.code,
        'quantity': _selectedQuantity,
        'title': '${_selectedService!.name} Campaign ($_selectedQuantity tasks)',
        'description': isCommentService ? 'Custom content campaign' : 'Direct promotional campaign',
        'requirements': {
          'targetUrl': _targetUrlController.text.trim(),
          'topic': _topicController.text.trim(),
          'language': _selectedLanguage,
          'tone': _selectedTone,
          'aiGeneratorEnabled': isCommentService,
          'sampleComments': _sampleComments,
          'appName': _appNameController.text.trim().isNotEmpty
              ? _appNameController.text.trim()
              : (_isYouTubeService(_selectedService) ? (_ytTitle ?? '') : (_appName ?? '')),
          'appIcon': _appIcon,
          'packageId': _packageId,
          'watchTimeSeconds': _ytRequiredWatchSeconds ??
              (_ytDurationSeconds != null
                  ? (_ytDurationSeconds! > 300 ? 300 : _ytDurationSeconds!)
                  : 0),
          'videoDurationSeconds': _ytDurationSeconds ?? 0,
          'videoTitle': _ytTitle ?? '',
          'videoThumbnail': _ytThumbnail ?? '',
        },
        'timeToAcceptHours': _selectedService!.minAcceptHours,
        'timeToCompleteHours': _selectedService!.maxCompleteHours > 48
            ? 48
            : _selectedService!.maxCompleteHours,
      };

      await _serviceRepository.dioClient!.post('/buyer/orders', data: orderPayload);

      setState(() => _isSubmitting = false);
      _loadWalletBalance();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Order Live!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully created ${_selectedService!.name} campaign for ${ServiceUnitHelper.getUnitName(_selectedService!.name, count: _selectedQuantity, includeCount: true)}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('₹${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedService = null;
                  _targetUrlController.clear();
                  _appNameController.clear();
                  _topicController.clear();
                  _appIcon = null;
                  _appName = null;
                  _packageId = null;
                  _sampleComments = [];
                  _ytTitle = null;
                  _ytThumbnail = null;
                });
              },
              child: const Text('Create Another'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Order failed: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (_selectedService != null) {
      return _buildOrderFormView();
    }

    return _buildCategoryAccordionCatalogView();
  }

  // ==================== VIEW 1: CATEGORY ACCORDION CATALOG ====================
  Widget _buildCategoryAccordionCatalogView() {
    // Group services by category
    final Map<String, List<ServiceModel>> grouped = {};
    for (var s in _publishedServices) {
      final codeUpper = s.code.toUpperCase();
      final nameUpper = s.name.toUpperCase();
      if (codeUpper.contains('TELEGRAM') || nameUpper.contains('TELEGRAM')) {
        continue; // Exclude Telegram services
      }
      String cat = s.category.trim();

      if (codeUpper.contains('PLAY') || codeUpper.contains('RATING') || (codeUpper.contains('REVIEW') && !codeUpper.contains('INSTA') && !codeUpper.contains('YT')) || nameUpper.contains('PLAY STORE')) {
        cat = 'Google Play Store';
      } else if (codeUpper.contains('APP') || codeUpper.contains('INSTALL') || nameUpper.contains('INSTALL')) {
        cat = 'App Install & Review';
      } else if (codeUpper.contains('YOUTUBE') || codeUpper.contains('YT') || nameUpper.contains('YOUTUBE')) {
        cat = 'YouTube';
      } else if (codeUpper.contains('INSTA') || nameUpper.contains('INSTAGRAM')) {
        cat = 'Instagram';
      } else if (codeUpper.contains('WEB') || codeUpper.contains('TRAFFIC') || codeUpper.contains('VISIT') || nameUpper.contains('WEBSITE')) {
        cat = 'Website Traffic';
      } else if (cat.isEmpty || cat == 'General') {
        cat = 'Other Services';
      }
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    // Category visual themes
    final Map<String, Map<String, dynamic>> categoryMeta = {
      'Google Play Store': {
        'icon': Icons.star_rate_rounded,
        'color': const Color(0xFF059669), // Emerald Green
      },
      'Play Store': {
        'icon': Icons.star_rate_rounded,
        'color': const Color(0xFF059669),
      },
      'YouTube': {
        'icon': Icons.play_circle_fill_rounded,
        'color': const Color(0xFFEF4444), // YouTube Red
      },
      'Instagram': {
        'icon': Icons.camera_alt_rounded,
        'color': const Color(0xFFEC4899), // Instagram Rose Pink
      },
      'App Install & Review': {
        'icon': Icons.android_rounded,
        'color': const Color(0xFF7C3AED), // App Violet
      },
      'Website Traffic': {
        'icon': Icons.language_rounded,
        'color': const Color(0xFFD97706), // Web Amber
      },
    };

    final priorityOrder = [
      'Google Play Store',
      'YouTube',
      'Instagram',
      'App Install & Review',
      'Website Traffic',
    ];
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        int idxA = priorityOrder.indexOf(a.key);
        int idxB = priorityOrder.indexOf(b.key);
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Catalog',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Select a category • Tap ℹ for full service details',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 16, color: Color(0xFFE11D48)),
                const SizedBox(width: 6),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE11D48),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Categories Accordion List sorted by priority
          ...sortedEntries.map((entry) {
            final cat = entry.key;
            final services = entry.value;
            final meta = categoryMeta[cat] ?? {
              'icon': Icons.stars_rounded,
              'color': const Color(0xFF6366F1),
            };

            return CategoryAccordionCard(
              categoryName: cat,
              icon: meta['icon'] as IconData,
              themeColor: meta['color'] as Color,
              services: services,
              initialExpanded: false, // All categories collapsed by default
              onSelectService: (service) => _selectService(service),
            );
          }),
        ],
      ),
    );
  }

  String? _getServiceAsset(ServiceModel s) {
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    if (code.contains('COMBO') || name.contains('COMBO')) return 'assets/icons/marketing.png';
    if (code.contains('FOLLOW') || name.contains('FOLLOW')) return 'assets/icons/instagram.png';
    if (code.contains('REVIEW') || name.contains('REVIEW')) return 'assets/icons/review.png';
    if (code.contains('RATING') || name.contains('RATING') || name.contains('STAR')) return 'assets/icons/rating.png';
    if (code.contains('COMMENT') || name.contains('COMMENT')) return 'assets/icons/comment.png';
    if (code.contains('SUB') || name.contains('SUB') || name.contains('SUBSCRIBE')) return 'assets/icons/subscribe.png';
    if (code.contains('LIKE') || name.contains('LIKE')) return 'assets/icons/like.png';
    if (code.contains('INSTALL') || name.contains('INSTALL') || code.contains('DOWNLOAD') || name.contains('DOWNLOAD')) {
      return 'assets/icons/smartphone.png';
    }
    if (code.contains('PLAY') || code.contains('WATCH') || name.contains('WATCH') || name.contains('VIEW')) {
      return 'assets/icons/play.png';
    }
    if (code.contains('PLAY') || code.contains('GOOGLE')) return 'assets/icons/google-play.png';
    if (code.contains('YT') || code.contains('YOUTUBE')) return 'assets/icons/youtube.png';
    if (code.contains('INSTA') || code.contains('IG')) return 'assets/icons/instagram.png';
    return null;
  }

  // ==================== VIEW 2: ORDER PLACEMENT VIEW ====================
  Widget _buildOrderFormView() {
    final s = _selectedService!;
    final isAi = _isCommentOrComboService(s);
    final totalCost = _calculateTotalCost();
    final sAsset = _getServiceAsset(s);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => setState(() => _selectedService = null),
        ),
        title: Row(
          children: [
            if (sAsset != null) ...[
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Image.asset(sAsset, fit: BoxFit.contain),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                        color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ServiceUnitHelper.getRateLabel(s.name, s.pricing.buyerPrice),
                    style: const TextStyle(
                        color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target URL Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.linkFieldLabel ?? 'Target Link / Video URL',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetUrlController,
                      keyboardType: TextInputType.url,
                      onChanged: _onTargetUrlChanged,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide target URL';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: s.linkFieldPlaceholder ?? 'https://www.youtube.com/watch?v=...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF2563EB)),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isPlayStoreService(_selectedService) &&
                                _targetUrlController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: InkWell(
                                  onTap: _isFetchingAppInfo
                                      ? null
                                      : () => _fetchPlayStoreAppInfo(_targetUrlController.text.trim()),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: _isFetchingAppInfo
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                                          )
                                        : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                            if ((_isYouTubeService(_selectedService) ||
                                    _targetUrlController.text.contains('youtu')) &&
                                _targetUrlController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: InkWell(
                                  onTap: _isFetchingYtInfo
                                      ? null
                                      : () => _fetchYouTubeVideoInfo(_targetUrlController.text.trim()),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: _isFetchingYtInfo
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                                          )
                                        : const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: _pasteFromClipboard,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF2563EB)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Paste',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),

                    // Play Store Loading State
                    if (_isFetchingAppInfo) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Fetching app details from Google Play Store...',
                                style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Play Store App Preview Card
                    if (_appName != null && _appName!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // App Icon
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: (_appIcon != null && _appIcon!.isNotEmpty)
                                        ? Image.network(
                                            _appIcon!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.shop_two_rounded,
                                              color: Color(0xFF10B981),
                                              size: 28,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.shop_two_rounded,
                                            color: Color(0xFF10B981),
                                            size: 28,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Title & Package
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _appName!,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF16A34A)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Detected',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_packageId != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _packageId!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: Color(0xFF16A34A)),
                                  SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Reviews will be customized specifically matching this app\'s features',
                                      style: TextStyle(fontSize: 10.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Fetch Error Hint (non-blocking)
                    if (_appFetchError != null && (_appName == null || _appName!.isEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(
                        '💡 ${_appFetchError!}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFD97706)),
                      ),
                    ],

                    // YouTube Loading State
                    if (_isFetchingYtInfo) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Extracting video length & watch time from YouTube...',
                                style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // YouTube Video Preview Card
                    if (_ytTitle != null && _ytTitle!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.5), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail with length badge
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 96,
                                        height: 60,
                                        color: Colors.black,
                                        child: (_ytThumbnail != null && _ytThumbnail!.isNotEmpty)
                                            ? Image.network(
                                                _ytThumbnail!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.white70,
                                                  size: 32,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white70,
                                                size: 32,
                                              ),
                                      ),
                                    ),
                                    if (_ytDurationFormatted != null)
                                      Positioned(
                                        bottom: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _ytDurationFormatted!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Title & Watch Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _ytTitle!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              'Total: ${_ytDurationFormatted ?? ''}',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _ytIsCappedAt5Min
                                                  ? const Color(0xFFFEF3C7)
                                                  : const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              _ytIsCappedAt5Min ? 'Capped at 5m' : 'Full Video',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _ytIsCappedAt5Min
                                                    ? const Color(0xFFB45309)
                                                    : const Color(0xFF15803D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _ytIsCappedAt5Min ? Icons.timer_outlined : Icons.check_circle_outline_rounded,
                                    size: 13,
                                    color: _ytIsCappedAt5Min ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _ytIsCappedAt5Min
                                          ? '5-Minute Cap Rule: Worker must watch 5 minutes before submit unlocks'
                                          : 'Worker must watch complete video before submit unlocks',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: _ytIsCappedAt5Min ? const Color(0xFF92400E) : const Color(0xFF166534),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // YouTube Error Hint
                    if (_ytFetchError != null && (_ytTitle == null || _ytTitle!.isEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(
                        '💡 ${_ytFetchError!}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Generator Options Widget (if AI is enabled)
              if (isAi) ...[
                AiCommentConfigWidget(
                  appNameController: _appNameController,
                  topicController: _topicController,
                  selectedLanguage: _selectedLanguage,
                  selectedTone: _selectedTone,
                  selectedQuantity: _selectedQuantity,
                  sampleComments: _sampleComments,
                  isGeneratingPreview: _isGeneratingPreview,
                  appName: _appNameController.text.trim().isNotEmpty
                      ? _appNameController.text.trim()
                      : (_isYouTubeService(s) ? _ytTitle : _appName),
                  isAppReview: s.code.toUpperCase().contains('PLAY') ||
                      s.code.toUpperCase().contains('REVIEW') ||
                      s.category.toUpperCase().contains('PLAY') ||
                      s.name.toUpperCase().contains('PLAY') ||
                      s.name.toUpperCase().contains('REVIEW'),
                  onGeneratePreview: _generateSampleComments,
                  onLanguageChanged: (lang) => setState(() {
                    _selectedLanguage = lang;
                    _sampleComments = [];
                  }),
                  onToneChanged: (tone) => setState(() {
                    _selectedTone = tone;
                    _sampleComments = [];
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // Quantity Selector Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ServiceUnitHelper.getQuantityHeader(s.name),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ServiceUnitHelper.getUnitExplanation(s.name),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stepper row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF2563EB)),
                          onPressed: () {
                            if (_selectedQuantity > 1) {
                              setState(() {
                                _selectedQuantity--;
                                _quantityController.text = '$_selectedQuantity';
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            onChanged: (val) {
                              final num = int.tryParse(val) ?? 1;
                              setState(() => _selectedQuantity = num > 0 ? num : 1);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                          onPressed: () {
                            setState(() {
                              _selectedQuantity++;
                              _quantityController.text = '$_selectedQuantity';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick presets
                    Wrap(
                      spacing: 8,
                      children: [10, 25, 50, 100, 500, 1000].map((qty) {
                        final isSelected = _selectedQuantity == qty;
                        return ChoiceChip(
                          label: Text(ServiceUnitHelper.getUnitName(s.name, count: qty, includeCount: true)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedQuantity = qty;
                              _quantityController.text = '$qty';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Total & Checkout Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(ServiceUnitHelper.getUnitName(s.name, count: _selectedQuantity, includeCount: true),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rate per ${ServiceUnitHelper.getUnitName(s.name, count: 1)}:',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹${s.pricing.buyerPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Budget:',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('₹${totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.w900,
                                fontSize: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitCampaign,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _isSubmitting ? 'Launching Campaign...' : 'Place Campaign Order',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
