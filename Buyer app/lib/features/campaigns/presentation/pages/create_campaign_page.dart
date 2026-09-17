import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/domain/models/service_model.dart';
import '../../../services/data/repositories/service_repository_impl.dart';
import '../../../services/presentation/widgets/category_accordion_card.dart';
import '../../../services/presentation/widgets/ai_comment_config_widget.dart';
import '../../../../core/utils/service_unit_helper.dart';
import '../../../wallet/presentation/pages/add_balance_screen.dart';

class CreateCampaignPage extends StatefulWidget {
  final String? serviceId;
  final VoidCallback? onBackToHome;

  const CreateCampaignPage({super.key, this.serviceId, this.onBackToHome});

  @override
  State<CreateCampaignPage> createState() => CreateCampaignPageState();
}

class CreateCampaignPageState extends State<CreateCampaignPage> {
  final ServiceRepositoryImpl _serviceRepository = ServiceRepositoryImpl();

  List<ServiceModel> _publishedServices = [];
  ServiceModel? _selectedService;
  bool _isLoading = true;

  /// Closes the order form if open and returns to the catalog.
  /// Returns true if handled (meaning it went from order form back to catalog),
  /// or false if the catalog was already displayed.
  bool handleBack() {
    if (_selectedService != null) {
      setState(() {
        _selectedService = null;
      });
      return true;
    }
    return false;
  }

  void _onUiBackPressed() {
    final handled = handleBack();
    if (!handled) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else if (widget.onBackToHome != null) {
        widget.onBackToHome!();
      }
    }
  }

  double _walletBalance = 0.0;

  // Order Form State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _targetUrlController = TextEditingController();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '10');
  int _selectedQuantity = 10;
  String _selectedLanguage = 'English';
  String _selectedTone = 'natural';
  bool _isSubmitting = false;
  List<String> _sampleComments = [];
  bool _isGeneratingPreview = false;
  int _minWords = 15;
  int _maxWords = 45;

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

  // Instagram Target Metadata State
  String? _instaTargetType;
  String? _instaIdentifier;

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

  bool _isGoogleBusinessService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();
    return code.contains('GOOGLE_BUSINESS') ||
        code.contains('GOOGLE_MAPS') ||
        code.contains('GMB') ||
        cat.contains('GOOGLE BUSINESS') ||
        cat.contains('GOOGLE MAPS') ||
        cat.contains('MAPS') ||
        name.contains('GOOGLE BUSINESS') ||
        name.contains('GOOGLE MAPS') ||
        desc.contains('GOOGLE MAPS') ||
        desc.contains('GOOGLE BUSINESS');
  }

  bool _isAppInstallService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();
    return code.contains('INSTALL') ||
        code.contains('DOWNLOAD') ||
        code.startsWith('APP_') ||
        code == 'APP_INSTALL' ||
        name.contains('INSTALL') ||
        name.contains('DOWNLOAD') ||
        cat.contains('INSTALL') ||
        cat.contains('APP') ||
        desc.contains('INSTALL');
  }

  bool _isPlayStoreService(ServiceModel? s) {
    if (s == null || _isGoogleBusinessService(s) || _isInstagramService(s)) {
      return false;
    }
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();
    return code.contains('PLAY') ||
        code.contains('REVIEW') ||
        code.contains('RATING') ||
        code.contains('INSTALL') ||
        code.contains('DOWNLOAD') ||
        code.startsWith('APP_') ||
        cat.contains('PLAY') ||
        cat.contains('INSTALL') ||
        cat.contains('APP') ||
        name.contains('PLAY') ||
        name.contains('REVIEW') ||
        name.contains('INSTALL') ||
        name.contains('DOWNLOAD') ||
        desc.contains('PLAY STORE') ||
        desc.contains('INSTALL');
  }

  bool _isInstagramService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    final desc = s.description.toUpperCase();
    final cat = s.category.toUpperCase();

    // Guard: Install / Download / App services are NEVER Instagram!
    if (code.contains('INSTALL') ||
        name.contains('INSTALL') ||
        cat.contains('INSTALL') ||
        desc.contains('INSTALL') ||
        cat.contains('APP') ||
        code.startsWith('APP_') ||
        code == 'APP_INSTALL') {
      return false;
    }

    return code.contains('INSTAGRAM') ||
        code.startsWith('IG_') ||
        code == 'IG' ||
        cat.contains('INSTAGRAM') ||
        name.contains('INSTAGRAM') ||
        desc.contains('INSTAGRAM') ||
        (code.contains('INSTA') && !code.contains('INSTALL')) ||
        (cat.contains('INSTA') && !cat.contains('INSTALL')) ||
        (name.contains('INSTA') && !name.contains('INSTALL'));
  }

  bool _isInstagramCombo(ServiceModel? s) {
    if (s == null) return false;
    if (!_isInstagramService(s)) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    return code.contains('COMBO') || name.contains('COMBO');
  }

  bool _isInstagramFollowerService(ServiceModel? s) {
    if (s == null || !_isInstagramService(s)) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    return code.contains('FOLLOW') ||
        name.contains('FOLLOWER') ||
        code.contains('INSTAGRAM_FOLLOW');
  }

  bool _isYouTubeService(ServiceModel? s) {
    if (s == null) return false;
    if (_isInstagramService(s)) return false;
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

  bool _isYouTubeCombo(ServiceModel? s) {
    if (s == null) return false;
    if (_isInstagramService(s) || _isInstagramCombo(s)) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    return (code.contains('COMBO') || name.contains('COMBO')) &&
        (code.contains('YT') ||
            code.contains('YOUTUBE') ||
            s.category.toUpperCase().contains('YOUTUBE'));
  }

  void _parseInstagramUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _instaTargetType = null;
        _instaIdentifier = null;
      });
      return;
    }

    String type = 'Instagram Target';
    String identifier = '';

    if (trimmed.startsWith('@')) {
      type = 'Instagram Profile';
      identifier = trimmed;
    } else {
      final uri = Uri.tryParse(trimmed);
      final path = uri?.path.toLowerCase() ?? trimmed.toLowerCase();
      if (path.contains('/reel/') || path.contains('/reels/')) {
        type = 'Instagram Reel';
        final match =
            RegExp(r'/reel(?:s)?/([a-zA-Z0-9_\-]+)').firstMatch(trimmed);
        if (match != null) {
          identifier = 'Reel: ${match.group(1)}';
        } else {
          identifier = 'Instagram Reel';
        }
      } else if (path.contains('/p/')) {
        type = 'Instagram Post';
        final match = RegExp(r'/p/([a-zA-Z0-9_\-]+)').firstMatch(trimmed);
        if (match != null) {
          identifier = 'Post: ${match.group(1)}';
        } else {
          identifier = 'Instagram Post';
        }
      } else if (path.contains('/tv/')) {
        type = 'Instagram Video';
        identifier = 'Instagram Video';
      } else {
        // Assume profile link e.g. instagram.com/username
        final match =
            RegExp(r'instagram\.com/([a-zA-Z0-9_\.]+)/?').firstMatch(trimmed);
        if (match != null &&
            !['p', 'reel', 'reels', 'stories', 'explore']
                .contains(match.group(1))) {
          type = 'Instagram Profile';
          identifier = '@${match.group(1)}';
        } else {
          type = 'Instagram Link';
          identifier = trimmed;
        }
      }
    }

    setState(() {
      _instaTargetType = type;
      _instaIdentifier = identifier.isNotEmpty ? identifier : trimmed;
      if (_appNameController.text.trim().isEmpty &&
          identifier.isNotEmpty &&
          !identifier.startsWith('http')) {
        _appNameController.text = identifier;
      }
    });
  }

  void _onTargetUrlChanged(String val) {
    final trimmed = val.trim();
    final isGoogleBusiness = _isGoogleBusinessService(_selectedService);
    final isPlayStore = _isPlayStoreService(_selectedService);
    final isInstagram = _isInstagramService(_selectedService) ||
        trimmed.contains('instagram.com') ||
        trimmed.startsWith('@');
    final isYouTube = _isYouTubeService(_selectedService) ||
        trimmed.contains('youtube.com') ||
        trimmed.contains('youtu.be');

    if (isGoogleBusiness || (!isPlayStore && !isYouTube && !isInstagram))
      return;
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

        _instaTargetType = null;
        _instaIdentifier = null;

        _sampleComments = [];
      });
      return;
    }

    if (isInstagram) {
      _parseInstagramUrl(trimmed);
      return;
    }

    if (isPlayStore) {
      if (_appFetchError != null) setState(() => _appFetchError = null);
      if (trimmed.length >= 5 &&
          (trimmed.contains('.') || trimmed.contains('/'))) {
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
      if (trimmed.length >= 10 &&
          (trimmed.contains('youtu.be') || trimmed.contains('youtube.com'))) {
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
          _ytRequiredWatchFormatted =
              data['requiredWatchFormatted']?.toString();
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
          _ytFetchError =
              err ?? 'Could not extract video duration from YouTube link.';
        });
      }
    } catch (err) {
      debugPrint('Error fetching YouTube metadata: $err');
      setState(() {
        _ytFetchError =
            'Could not fetch video info. You can still proceed normally.';
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
        _appFetchError =
            'Could not fetch app info. You can still proceed normally.';
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingAppInfo = false);
      }
    }
  }

  bool _isCommentOrComboService(ServiceModel? s) {
    if (s == null) return false;
    // Instagram services: Combo and Comment services have AI comment generator!
    if (_isInstagramService(s)) {
      final code = s.code.toUpperCase();
      final name = s.name.toUpperCase();
      return _isInstagramCombo(s) ||
          code.contains('COMMENT') ||
          name.contains('COMMENT');
    }
    // YouTube Combo IS a comment service (Watch + Like + Sub + Comment)
    if (_isYouTubeCombo(s)) {
      return true;
    }
    final code = s.code.toUpperCase();
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

  bool _isComboService(ServiceModel? s) {
    if (s == null) return false;
    final code = s.code.toUpperCase();
    final name = s.name.toUpperCase();
    return code.contains('COMBO') || name.contains('COMBO');
  }

  Future<void> _generateSampleComments() async {
    setState(() => _isGeneratingPreview = true);
    final userAppName = _appNameController.text.trim().isNotEmpty
        ? _appNameController.text.trim()
        : (_isYouTubeService(_selectedService)
            ? (_ytTitle ?? '')
            : (_appName ?? ''));
    final cleanBrand = userAppName.split(RegExp(r'[:\-|–—•(]'))[0].trim();
    final userPrompt = _topicController.text.trim();

    try {
      if (_serviceRepository.dioClient == null) {
        throw Exception(
            'Not connected to API server. Please check your internet connection.');
      }

      final res = await _serviceRepository.dioClient!.post(
        '/buyer/orders/ai-preview-comments',
        data: {
          'topic': userPrompt,
          'prompt': userPrompt,
          'language': _selectedLanguage,
          'tone': _selectedTone,
          'count': _selectedQuantity,
          'minWords': _minWords,
          'maxWords': _maxWords,
          'serviceCode': _selectedService?.code,
          'targetUrl': _targetUrlController.text.trim(),
          'appName': cleanBrand,
          'businessName': cleanBrand,
          'videoTitle': _isYouTubeService(_selectedService)
              ? (_ytTitle?.isNotEmpty == true ? _ytTitle! : userAppName)
              : '',
        },
      );

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data != null &&
          res.data['sampleComments'] != null) {
        final List comments = res.data['sampleComments'];
        if (comments.isNotEmpty) {
          setState(() {
            _sampleComments = comments
                .map((c) => _sanitizeCommentText(c.toString()))
                .map((c) => _trimToWordLimit(c, _minWords, _maxWords))
                .where((c) => c.isNotEmpty)
                .toList();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✓ Successfully generated ${_sampleComments.length} comments via DeepSeek AI'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      throw Exception(res.data?['message'] ?? 'AI returned empty comments.');
    } catch (apiErr) {
      String errMsg = 'AI Agent Failed to generate comments.';
      if (apiErr is DioException) {
        final serverMsg = apiErr.response?.data?['message'];
        final errObj = apiErr.response?.data?['error'];
        if (serverMsg != null) {
          errMsg =
              serverMsg is List ? serverMsg.join(', ') : serverMsg.toString();
        } else if (errObj != null) {
          if (errObj is Map && errObj['message'] != null) {
            errMsg = errObj['message'].toString();
          } else {
            errMsg = errObj.toString();
          }
        } else {
          errMsg = apiErr.message ?? errMsg;
        }
      } else {
        errMsg = apiErr.toString().replaceFirst('Exception: ', '');
      }

      setState(() {
        _sampleComments = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '❌ $errMsg',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 5),
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
        .replaceAll(
            RegExp(
                r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{1FA70}-\u{1FAFF}⭐★🌟✨🌠🎖️🏅🏆💯🔥👍👎]',
                unicode: true),
            '')
        .replaceAll(RegExp(r'\b5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5\s*\/\s*5\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfive\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b5-star\s*(rating)?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bfull\s*5\s*stars?\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+([.,!?])'), r'$1')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _trimToWordLimit(String text, int minWords, int maxWords) {
    final words =
        text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= maxWords) return text;

    final subWords = words.take(maxWords).toList();
    final candidate = subWords.join(' ');

    // If there is an early complete sentence (at least 3 words)
    final match = RegExp(r'^(.+?[.!?])(?:\s+.*)?$').firstMatch(candidate);
    if (match != null) {
      final sentence = match.group(1)!.trim();
      final sentenceWords =
          sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      if (sentenceWords >= (minWords <= 5 ? 3 : (minWords - 1))) {
        return sentence;
      }
    }

    final cleaned = candidate
        .replaceAll(RegExp(r'[,;:\-\s]+$'), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
    return '$cleaned.';
  }

  Future<void> _loadWalletBalance() async {
    try {
      if (_serviceRepository.dioClient != null) {
        final res =
            await _serviceRepository.dioClient!.get('/buyer/wallet/balance');
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
      final minQ =
          service.pricing.minQuantity > 0 ? service.pricing.minQuantity : 10;
      _selectedQuantity = minQ > 10 ? minQ : 10;
      _quantityController.text = '$_selectedQuantity';
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
      final deficit = totalCost - _walletBalance;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Insufficient balance (₹${_walletBalance.toStringAsFixed(2)}). Need: ₹${totalCost.toStringAsFixed(2)} (Deficit: ₹${deficit.toStringAsFixed(2)})'),
          backgroundColor: const Color(0xFFC2410C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Top Up Now',
            textColor: const Color(0xFFFDE047),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddBalanceScreen(initialAmount: deficit),
                ),
              );
              _loadWalletBalance();
            },
          ),
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
        'title':
            '${_selectedService!.name} Campaign ($_selectedQuantity tasks)',
        'description': isCommentService
            ? 'Custom content campaign'
            : 'Direct promotional campaign',
        'requirements': {
          'targetUrl': _targetUrlController.text.trim(),
          'topic': _topicController.text.trim(),
          'language': _selectedLanguage,
          'tone': _selectedTone,
          'aiGeneratorEnabled': isCommentService,
          'minWords': _minWords,
          'maxWords': _maxWords,
          'sampleComments': _sampleComments,
          'appName': _appNameController.text.trim().isNotEmpty
              ? _appNameController.text.trim()
              : (_isInstagramService(_selectedService)
                  ? (_instaIdentifier ?? '')
                  : (_isYouTubeService(_selectedService)
                      ? (_ytTitle ?? '')
                      : (_appName ?? ''))),
          'businessName': _isGoogleBusinessService(_selectedService)
              ? (_appNameController.text.trim().isNotEmpty
                  ? _appNameController.text.trim()
                  : (_appName ?? ''))
              : '',
          'appIcon': _appIcon,
          'packageId': _packageId,
          'watchTimeSeconds': _isInstagramService(_selectedService)
              ? 0
              : (_ytRequiredWatchSeconds ??
                  (_ytDurationSeconds != null
                      ? (_ytDurationSeconds! > 300 ? 300 : _ytDurationSeconds!)
                      : (_isYouTubeService(_selectedService) ? 120 : 0))),
          'videoDurationSeconds': _isInstagramService(_selectedService)
              ? 0
              : (_ytDurationSeconds ??
                  (_isYouTubeService(_selectedService) ? 120 : 0)),
          'videoTitle':
              _isInstagramService(_selectedService) ? '' : (_ytTitle ?? ''),
          'videoThumbnail':
              _isInstagramService(_selectedService) ? '' : (_ytThumbnail ?? ''),
        },
        'timeToAcceptHours': _selectedService!.minAcceptHours,
        'timeToCompleteHours': _selectedService!.maxCompleteHours > 48
            ? 48
            : _selectedService!.maxCompleteHours,
      };

      await _serviceRepository.dioClient!
          .post('/buyer/orders', data: orderPayload);

      setState(() => _isSubmitting = false);
      _loadWalletBalance();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Text('Order Live!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Successfully created ${_selectedService!.name} campaign for ${ServiceUnitHelper.getUnitName(_selectedService!.name, serviceCode: _selectedService!.code, count: _selectedQuantity, includeCount: true)}.',
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
                    const Text('Total Paid:',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('₹${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981))),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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

    final Widget content = _selectedService != null
        ? _buildOrderFormView()
        : _buildCategoryAccordionCatalogView();

    // If hosted inside MainNavigationPage with onBackToHome provided,
    // the parent PopScope manages the back event via handleBack() to avoid conflicts.
    if (widget.onBackToHome != null) {
      return content;
    }

    // If pushed as a standalone route (e.g. from Services or Home banner),
    // intercept back on order form to return to catalog, or pop to previous route if already on catalog.
    return PopScope(
      canPop: _selectedService == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedService != null) {
          setState(() {
            _selectedService = null;
          });
        }
      },
      child: content,
    );
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

      if (codeUpper.contains('GOOGLE_BUSINESS') ||
          codeUpper.contains('GOOGLE_MAP') ||
          codeUpper.contains('GMB') ||
          nameUpper.contains('GOOGLE BUSINESS') ||
          nameUpper.contains('GOOGLE MAP') ||
          cat.toLowerCase().contains('google business') ||
          cat.toLowerCase().contains('google maps')) {
        cat = 'Google Maps';
      } else if (codeUpper.contains('INSTALL') ||
          codeUpper.startsWith('APP_') ||
          nameUpper.contains('INSTALL') ||
          cat.toLowerCase().contains('install')) {
        cat = 'App Install & Review';
      } else if (codeUpper.contains('PLAY') ||
          codeUpper.contains('RATING') ||
          (codeUpper.contains('REVIEW') &&
              !codeUpper.contains('INSTA') &&
              !codeUpper.contains('YT')) ||
          nameUpper.contains('PLAY STORE') ||
          cat.toLowerCase().contains('play store')) {
        cat = 'Google Play Store';
      } else if (codeUpper.contains('YOUTUBE') ||
          codeUpper.contains('YT') ||
          nameUpper.contains('YOUTUBE')) {
        cat = 'YouTube';
      } else if ((codeUpper.contains('INSTA') &&
              !codeUpper.contains('INSTALL')) ||
          nameUpper.contains('INSTAGRAM')) {
        cat = 'Instagram';
      } else if (codeUpper.contains('WEB') ||
          codeUpper.contains('TRAFFIC') ||
          codeUpper.contains('VISIT') ||
          nameUpper.contains('WEBSITE')) {
        cat = 'Website Traffic';
      } else if (cat.isEmpty || cat == 'General') {
        cat = 'Other Services';
      }
      grouped.putIfAbsent(cat, () => []).add(s);
    }

    // Sort sub-services within each category so COMBO services appear on top
    for (var list in grouped.values) {
      list.sort((a, b) {
        final aIsCombo = a.serviceType.toLowerCase() == 'combo' ||
            a.code.toUpperCase().contains('COMBO') ||
            a.name.toUpperCase().contains('COMBO');
        final bIsCombo = b.serviceType.toLowerCase() == 'combo' ||
            b.code.toUpperCase().contains('COMBO') ||
            b.name.toUpperCase().contains('COMBO');
        if (aIsCombo && !bIsCombo) return -1;
        if (!aIsCombo && bIsCombo) return 1;
        return 0;
      });
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
      'Google Maps': {
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF4285F4), // Google Blue
      },
      'Google Business': {
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF4285F4),
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
      'Play Store',
      'Google Maps',
      'Google Business',
      'YouTube',
      'Instagram',
      'App Install & Review',
      'Mobile Apps',
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

    final bool canGoBack =
        Navigator.canPop(context) || widget.onBackToHome != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF0F172A)),
                tooltip: 'Back',
                onPressed: _onUiBackPressed,
              )
            : null,
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
            final meta = categoryMeta[cat] ??
                {
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
    if (code.contains('GOOGLE_BUSINESS') ||
        code.contains('GOOGLE_MAP') ||
        name.contains('GOOGLE BUSINESS') ||
        name.contains('GOOGLE MAP')) {
      return (code.contains('REVIEW') || name.contains('REVIEW'))
          ? 'assets/icons/review.png'
          : 'assets/icons/rating.png';
    }
    if (code.contains('COMBO') || name.contains('COMBO')) {
      return 'assets/icons/marketing.png';
    }
    if (_isAppInstallService(s) ||
        code.contains('INSTALL') ||
        name.contains('INSTALL') ||
        code.startsWith('APP_') ||
        code == 'APP_INSTALL') {
      return 'assets/icons/app_install.png';
    }
    if (_isInstagramService(s)) {
      if (code.contains('LIKE') || name.contains('LIKE')) {
        return 'assets/icons/like.png';
      }
      if (code.contains('COMMENT') || name.contains('COMMENT')) {
        return 'assets/icons/comment.png';
      }
      return 'assets/icons/instagram.png';
    }
    if (code.contains('REVIEW') || name.contains('REVIEW')) {
      return 'assets/icons/review.png';
    }
    if (code.contains('RATING') ||
        name.contains('RATING') ||
        name.contains('STAR')) return 'assets/icons/rating.png';
    if (code.contains('COMMENT') || name.contains('COMMENT')) {
      return 'assets/icons/comment.png';
    }
    if (code.contains('SUB') ||
        name.contains('SUB') ||
        name.contains('SUBSCRIBE')) return 'assets/icons/subscribe.png';
    if (code.contains('LIKE') || name.contains('LIKE')) {
      return 'assets/icons/like.png';
    }
    if (code.contains('INSTALL') ||
        name.contains('INSTALL') ||
        code.contains('DOWNLOAD') ||
        name.contains('DOWNLOAD')) {
      return 'assets/icons/app_install.png';
    }
    if (code.contains('PLAY') ||
        code.contains('WATCH') ||
        name.contains('WATCH') ||
        name.contains('VIEW')) {
      return 'assets/icons/play.png';
    }
    if (code.contains('PLAY') || code.contains('GOOGLE')) {
      return 'assets/icons/google-play.png';
    }
    if (code.contains('YT') || code.contains('YOUTUBE')) {
      return 'assets/icons/youtube.png';
    }
    if (code.contains('INSTA') && !code.contains('INSTALL')) {
      return 'assets/icons/instagram.png';
    }
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
          tooltip: 'Back to Catalog',
          onPressed: _onUiBackPressed,
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
                        color: Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    ServiceUnitHelper.getRateLabel(s.name, s.pricing.buyerPrice,
                        serviceCode: s.code),
                    style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
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
              // ── SPECIAL COMBO INCLUSIONS PERKS CARD ──
              if (_isComboService(s)) ...[
                _buildComboInclusionsCard(s),
                const SizedBox(height: 16),
              ],

              // ── SPECIAL APP INSTALL INCLUSIONS CARD ──
              if (_isAppInstallService(s)) ...[
                _buildAppInstallInclusionsCard(s),
                const SizedBox(height: 16),
              ],

              // ── SPECIAL GOOGLE BUSINESS PERKS CARD ──
              if (_isGoogleBusinessService(s)) ...[
                _buildGoogleBusinessInclusionsCard(s),
                const SizedBox(height: 16),
              ],

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
                      _isInstagramCombo(s)
                          ? 'Instagram Post / Reel or Profile Link (Target for Like, Follow & Comment)'
                          : (_isInstagramService(s)
                              ? (_isInstagramFollowerService(s)
                                  ? 'Instagram Profile Link / Username'
                                  : 'Instagram Reel or Post URL')
                              : (_isYouTubeCombo(s)
                                  ? 'YouTube Video Link (Target for Watch, Like, Subscribe & Comment)'
                                  : (_isYouTubeService(s)
                                      ? 'YouTube Video Link (Target URL)'
                                      : (_isGoogleBusinessService(s)
                                          ? 'Google Maps Business Listing Link'
                                          : (_isAppInstallService(s)
                                              ? 'Google Play Store App URL (Target App for Install)'
                                              : (_isPlayStoreService(s)
                                                  ? 'Google Play Store App Link / Package URL'
                                                  : (s.linkFieldLabel ??
                                                      'Target Link / URL'))))))),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetUrlController,
                      onChanged: _onTargetUrlChanged,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a target link';
                        }
                        final trimmed = val.trim();
                        if (_isInstagramService(s) && trimmed.startsWith('@')) {
                          return null;
                        }
                        if (!trimmed.startsWith('http://') &&
                            !trimmed.startsWith('https://')) {
                          return 'Please enter a valid URL (starting with https://)';
                        }
                        return null;
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isInstagramCombo(s)
                            ? 'https://www.instagram.com/p/... or /reel/... or /your_username'
                            : (_isInstagramService(s)
                                ? (_isInstagramFollowerService(s)
                                    ? 'https://instagram.com/your_username or @username'
                                    : 'https://www.instagram.com/reel/... or /p/...')
                                : (_isYouTubeCombo(s)
                                    ? 'https://www.youtube.com/watch?v=... or youtu.be/...'
                                    : (_isYouTubeService(s)
                                        ? 'https://www.youtube.com/watch?v=... or youtu.be/...'
                                        : (_isGoogleBusinessService(s)
                                            ? 'https://maps.app.goo.gl/... or Google Maps listing link'
                                            : (_isAppInstallService(s) ||
                                                    _isPlayStoreService(s)
                                                ? 'https://play.google.com/store/apps/details?id=com.your.app'
                                                : (s.linkFieldPlaceholder ??
                                                    'https://...')))))),
                        hintStyle: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(
                          _isInstagramService(s)
                              ? Icons.camera_alt_rounded
                              : (_isGoogleBusinessService(s)
                                  ? Icons.location_on_rounded
                                  : (_isYouTubeService(s)
                                      ? Icons.play_arrow_rounded
                                      : (_isAppInstallService(s)
                                          ? Icons.install_mobile_rounded
                                          : (_isPlayStoreService(s)
                                              ? Icons.shop_two_rounded
                                              : Icons.link_rounded)))),
                          color: _isInstagramService(s)
                              ? const Color(0xFFE1306C)
                              : (_isGoogleBusinessService(s)
                                  ? const Color(0xFF2563EB)
                                  : (_isYouTubeService(s)
                                      ? const Color(0xFFDC2626)
                                      : (_isAppInstallService(s)
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFF059669)))),
                        ),
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
                                      : () => _fetchPlayStoreAppInfo(
                                          _targetUrlController.text.trim()),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: _isFetchingAppInfo
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF2563EB)),
                                          )
                                        : const Icon(Icons.refresh_rounded,
                                            size: 16, color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),
                            if (!_isInstagramService(_selectedService) &&
                                (_isYouTubeService(_selectedService) ||
                                    _targetUrlController.text
                                        .contains('youtu')) &&
                                _targetUrlController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: InkWell(
                                  onTap: _isFetchingYtInfo
                                      ? null
                                      : () => _fetchYouTubeVideoInfo(
                                          _targetUrlController.text.trim()),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFFECACA)),
                                    ),
                                    child: _isFetchingYtInfo
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFDC2626)),
                                          )
                                        : const Icon(Icons.refresh_rounded,
                                            size: 16, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: _pasteFromClipboard,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isInstagramService(s)
                                      ? const Color(0xFFFDF2F8)
                                      : (_isAppInstallService(s)
                                          ? const Color(0xFFFAF5FF)
                                          : const Color(0xFFEFF6FF)),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _isInstagramService(s)
                                          ? const Color(0xFFFBCFE8)
                                          : (_isAppInstallService(s)
                                              ? const Color(0xFFE9D5FF)
                                              : const Color(0xFFBFDBFE))),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.content_paste_rounded,
                                        size: 14,
                                        color: _isInstagramService(s)
                                            ? const Color(0xFFE1306C)
                                            : (_isAppInstallService(s)
                                                ? const Color(0xFF7C3AED)
                                                : const Color(0xFF2563EB))),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Paste',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _isInstagramService(s)
                                            ? const Color(0xFFE1306C)
                                            : (_isAppInstallService(s)
                                                ? const Color(0xFF7C3AED)
                                                : const Color(0xFF2563EB)),
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
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _isInstagramService(s)
                                ? const Color(0xFFE1306C)
                                : (_isYouTubeService(s)
                                    ? const Color(0xFFDC2626)
                                    : (_isAppInstallService(s)
                                        ? const Color(0xFF7C3AED)
                                        : const Color(0xFF2563EB))),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Instagram Target Preview Card
                    if ((_isInstagramService(s) ||
                            _targetUrlController.text
                                .contains('instagram.com') ||
                            _targetUrlController.text.startsWith('@')) &&
                        _instaIdentifier != null &&
                        _instaIdentifier!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                const Color(0xFFF472B6).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF833AB4),
                                        Color(0xFFFD1D1D),
                                        Color(0xFFF77737),
                                      ],
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _instaIdentifier!,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFCE7F3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 11,
                                                    color: Color(0xFFDB2777)),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Detected',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFDB2777),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _instaTargetType ?? 'Instagram Target',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFBE185D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFFFBCFE8)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_user_rounded,
                                      size: 12, color: Color(0xFFDB2777)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _instaTargetType == 'Instagram Profile'
                                          ? 'Real active Indian Instagram profiles will follow this handle'
                                          : 'Workers will directly open this ${_instaTargetType?.toLowerCase() ?? "reel/post"} on Instagram app',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF9D174D),
                                        fontWeight: FontWeight.w600,
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

                    // Play Store Loading State
                    if (_isFetchingAppInfo) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF2563EB)),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Fetching app details from Google Play Store...',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E40AF),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Play Store App Preview Card
                    if (_isPlayStoreService(_selectedService) &&
                        _appName != null &&
                        _appName!.isNotEmpty) ...[
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
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: (_appIcon != null &&
                                            _appIcon!.isNotEmpty)
                                        ? Image.network(
                                            _appIcon!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded,
                                                    size: 11,
                                                    color: Color(0xFF16A34A)),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 12, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      _isAppInstallService(_selectedService)
                                          ? 'Real Android users will search, install & test this app on physical devices'
                                          : 'Reviews will be customized specifically matching this app\'s features',
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF166534),
                                          fontWeight: FontWeight.w600),
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
                    if (_appFetchError != null &&
                        (_appName == null || _appName!.isEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(
                        '💡 ${_appFetchError!}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFD97706)),
                      ),
                    ],

                    // YouTube Loading State
                    if (!_isInstagramService(s) && _isFetchingYtInfo) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFFDC2626)),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Extracting video length & watch time from YouTube...',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // YouTube Video Preview Card
                    if (!_isInstagramService(s) &&
                        _ytTitle != null &&
                        _ytTitle!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFF87171)
                                  .withValues(alpha: 0.5),
                              width: 1.2),
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
                                        child: (_ytThumbnail != null &&
                                                _ytThumbnail!.isNotEmpty)
                                            ? Image.network(
                                                _ytThumbnail!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black
                                                .withValues(alpha: 0.85),
                                            borderRadius:
                                                BorderRadius.circular(4),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius:
                                                  BorderRadius.circular(5),
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _ytIsCappedAt5Min
                                                  ? const Color(0xFFFEF3C7)
                                                  : const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              _ytIsCappedAt5Min
                                                  ? 'Capped at 5m'
                                                  : 'Full Video',
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 13,
                                    color: Color(0xFF16A34A),
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Worker must watch complete video before submit unlocks',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
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
                    if (!_isInstagramService(s) &&
                        _ytFetchError != null &&
                        (_ytTitle == null || _ytTitle!.isEmpty)) ...[
                      const SizedBox(height: 10),
                      Text(
                        '💡 ${_ytFetchError!}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFDC2626)),
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
                      : (_isInstagramService(s)
                          ? (_instaIdentifier ?? '')
                          : (_isYouTubeService(s) ? _ytTitle : _appName)),
                  isAppReview: _isPlayStoreService(s),
                  isGoogleBusiness: _isGoogleBusinessService(s),
                  isInstagram: _isInstagramService(s),
                  onGeneratePreview: _generateSampleComments,
                  onLanguageChanged: (lang) => setState(() {
                    _selectedLanguage = lang;
                    _sampleComments = [];
                  }),
                  onToneChanged: (tone) => setState(() {
                    _selectedTone = tone;
                    _sampleComments = [];
                  }),
                  minWords: _minWords,
                  maxWords: _maxWords,
                  onWordLimitChanged: (min, max) => setState(() {
                    _minWords = min;
                    _maxWords = max;
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
                      ServiceUnitHelper.getQuantityHeader(s.name,
                          serviceCode: s.code),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ServiceUnitHelper.getUnitExplanation(s.name,
                          serviceCode: s.code),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),

                    // Stepper row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFF2563EB)),
                          onPressed: () {
                            final minQ = s.pricing.minQuantity > 0
                                ? s.pricing.minQuantity
                                : 1;
                            if (_selectedQuantity > minQ) {
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A)),
                            onChanged: (val) {
                              final minQ = s.pricing.minQuantity > 0
                                  ? s.pricing.minQuantity
                                  : 1;
                              final num = int.tryParse(val) ?? minQ;
                              setState(() =>
                                  _selectedQuantity = num >= minQ ? num : minQ);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFF2563EB)),
                          onPressed: () {
                            final maxQ = s.pricing.maxQuantity > 0
                                ? s.pricing.maxQuantity
                                : 99999;
                            if (_selectedQuantity < maxQ) {
                              setState(() {
                                _selectedQuantity++;
                                _quantityController.text = '$_selectedQuantity';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick presets
                    Wrap(
                      spacing: 8,
                      children: [
                        if (s.pricing.minQuantity <= 5) 5,
                        10,
                        25,
                        50,
                        100,
                        if (s.pricing.maxQuantity >= 250) 250,
                        if (s.pricing.maxQuantity >= 500) 500,
                        if (s.pricing.maxQuantity >= 1000) 1000,
                      ].toSet().map((qty) {
                        final isSelected = _selectedQuantity == qty;
                        return ChoiceChip(
                          label: Text(ServiceUnitHelper.getUnitName(s.name,
                              serviceCode: s.code,
                              count: qty,
                              includeCount: true)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
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
                        const Text('Quantity:',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                            ServiceUnitHelper.getUnitName(s.name,
                                serviceCode: s.code,
                                count: _selectedQuantity,
                                includeCount: true),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Rate per ${ServiceUnitHelper.getUnitName(s.name, serviceCode: s.code, count: 1)}:',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        Text('₹${s.pricing.buyerPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Budget:',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitCampaign,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Launching Campaign...'
                        : 'Place Campaign Order',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Install Perks & Inclusions Card (Explains Play Store Search, Download, 30s Usage) ──
  Widget _buildAppInstallInclusionsCard(ServiceModel s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9D5FF),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.install_mobile_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'REAL APP INSTALL & TESTING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE9D5FF),
                  ),
                ),
                child: Text(
                  'Per 1 App Install',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF6D28D9),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Every 1 Worker executes on their personal Android smartphone:',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildActionPerkTile(
            icon: Icons.search_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Google Play Store Search & Download',
            desc:
                'Worker searches your app on Play Store and installs directly on physical phone',
          ),
          const SizedBox(height: 6),
          _buildActionPerkTile(
            icon: Icons.timer_outlined,
            iconColor: const Color(0xFF2563EB),
            title: '30-60s In-App Testing Session',
            desc:
                'Opens the app and interacts for at least 30-60 seconds for verified engagement',
          ),
          const SizedBox(height: 6),
          _buildActionPerkTile(
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Screenshot Proof & Package Verification',
            desc:
                'System verifies genuine installation proof before task completion reward',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF6D28D9),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '100% Real Physical Android Phones • Safe for Google Play Store ASO & Trending',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B21B6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Combo Perks & Inclusions Widget (Explains WatchTime + Like + Sub + Comment) ──
  Widget _buildComboInclusionsCard(ServiceModel s) {
    final isYt = _isYouTubeCombo(s);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isYt
              ? [const Color(0xFFFEF2F2), const Color(0xFFFFF7ED)]
              : [const Color(0xFFFDF2F8), const Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isYt ? const Color(0xFFFECACA) : const Color(0xFFFBCFE8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isYt
                        ? [const Color(0xFFDC2626), const Color(0xFFEA580C)]
                        : [const Color(0xFFDB2777), const Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isYt ? Icons.auto_awesome_rounded : Icons.star_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isYt ? '4-IN-1 VIRAL BUNDLE' : '2-IN-1 GROWTH BUNDLE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isYt
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFFBCFE8),
                  ),
                ),
                child: Text(
                  'Per 1 Unit Combo',
                  style: GoogleFonts.outfit(
                    color: isYt
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF9D174D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isYt
                ? 'Every 1 Worker executes all FOUR (4) actions on your video:'
                : 'Every 1 Worker executes BOTH (2) actions on your profile:',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (isYt) ...[
            _buildActionPerkTile(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFFDC2626),
              title: 'Full Video Watch Time',
              desc:
                  'Worker watches complete video (100% full retention guaranteed)',
            ),
            const SizedBox(height: 6),
            _buildActionPerkTile(
              icon: Icons.thumb_up_alt_rounded,
              iconColor: const Color(0xFFEA580C),
              title: 'Video Like',
              desc: 'Authentic thumbs-up like from real active user',
            ),
            const SizedBox(height: 6),
            _buildActionPerkTile(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Channel Subscribe',
              desc: 'Permanent active channel subscriber (Non-drop guaranteed)',
            ),
            const SizedBox(height: 6),
            _buildActionPerkTile(
              icon: Icons.mode_comment_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Video Comment',
              desc:
                  'Authentic, topic-relevant positive comment posted on video',
            ),
          ] else ...[
            _buildActionPerkTile(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: const Color(0xFFDB2777),
              title: 'Profile Follower',
              desc: 'Permanent follow from authentic real active profile',
            ),
            const SizedBox(height: 6),
            _buildActionPerkTile(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE11D48),
              title: 'Post / Reel Like',
              desc: 'Genuine engagement like on latest post or reel',
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isYt
                  ? const Color(0xFFFEE2E2).withValues(alpha: 0.7)
                  : const Color(0xFFFCE7F3).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color:
                      isYt ? const Color(0xFFB91C1C) : const Color(0xFFBE185D),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isYt
                        ? '1 Combo = 1 Watch + 1 Like + 1 Subscribe + 1 Comment (All-in-One)'
                        : '1 Combo = 1 Profile Follow + 1 Post Like (All-in-One)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isYt
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF9D174D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPerkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, size: 10, color: Color(0xFF16A34A)),
                SizedBox(width: 2),
                Text(
                  'Included',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Google Business Perks Card (Explains Organic Google Maps Ranking & Reviews) ──
  Widget _buildGoogleBusinessInclusionsCard(ServiceModel s) {
    final bool isReview = s.code.toUpperCase().contains('REVIEW') ||
        s.name.toUpperCase().contains('REVIEW');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isReview
                          ? '5-STAR RATING & REVIEW'
                          : '5-STAR RATING GUARANTEE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  '100% Real Customers',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Authentic Local Business Growth for your Google Maps Listing:',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildActionPerkTile(
            icon: Icons.person_pin_circle_rounded,
            iconColor: const Color(0xFF2563EB),
            title: 'Real Local Accounts',
            desc:
                'Real active Google users with genuine Indian Google profiles',
          ),
          const SizedBox(height: 6),
          _buildActionPerkTile(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Guaranteed 5-Star Rating',
            desc:
                'Permanent 5-star rating directly on your Google Business page',
          ),
          if (isReview) ...[
            const SizedBox(height: 6),
            _buildActionPerkTile(
              icon: Icons.reviews_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Detailed Positive Review',
              desc:
                  'Customized review highlighting your staff, service quality & experience',
            ),
          ],
          const SizedBox(height: 6),
          _buildActionPerkTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Local SEO Boost',
            desc: 'Helps improve your Google Maps and local search prominence',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Color(0xFF1D4ED8),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isReview
                        ? '1 Unit = 1 Authentic 5-Star Google Rating + 1 Unique Custom Review'
                        : '1 Unit = 1 Authentic 5-Star Google Maps Rating',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
