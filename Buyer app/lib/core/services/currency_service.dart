import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Currency Service for Buyer App
/// Supports dynamic switching between INR (₹) and USD ($).
/// Features:
/// 1. Admin controls global default & exchange rate on server.
/// 2. If Buyer toggles locally, it saves to SharedPreferences and overrides ONLY for this buyer.
/// 3. Strict 1-Minute Rate Limiter: When buyer toggles ON/OFF rapidly, it uses cached rate
///    and blocks redundant server fetches (max 1 fetch per 60 seconds).
class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  static const String _prefKeyOverride = 'buyer_currency_override';
  static const String _prefKeyCachedRate = 'buyer_cached_usd_rate';
  static const String _prefKeyCachedAdminDefault = 'buyer_cached_admin_default';
  static const String _apiUrl = 'https://reviewsgateway.in/support-chat/api/support/currency-settings';

  String _currentCurrency = 'INR';
  double _usdExchangeRate = 85.0;
  String _adminDefaultCurrency = 'INR';
  bool _hasUserOverride = false;
  DateTime? _lastFetchTime;

  /// Reactive Notifier: UI listens to this to rebuild prices across the app instantly
  final ValueNotifier<String> currencyNotifier = ValueNotifier<String>('INR');

  String get currentCurrency => _currentCurrency;
  bool get isUSD => _currentCurrency == 'USD';
  String get symbol => isUSD ? '\$' : '₹';
  double get usdExchangeRate => _usdExchangeRate;
  bool get hasUserOverride => _hasUserOverride;

  /// Initialize service on app start
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString(_prefKeyOverride);
      final cachedRate = prefs.getDouble(_prefKeyCachedRate);
      final cachedAdmin = prefs.getString(_prefKeyCachedAdminDefault);

      if (cachedRate != null && cachedRate > 0) {
        _usdExchangeRate = cachedRate;
      }
      if (cachedAdmin != null && (cachedAdmin == 'USD' || cachedAdmin == 'INR')) {
        _adminDefaultCurrency = cachedAdmin;
      }

      if (override != null && (override == 'USD' || override == 'INR')) {
        _hasUserOverride = true;
        _currentCurrency = override;
      } else {
        _hasUserOverride = false;
        _currentCurrency = _adminDefaultCurrency;
      }

      currencyNotifier.value = _currentCurrency;
      debugPrint('[CurrencyService] Initialized: $_currentCurrency (isOverride: $_hasUserOverride, Rate: $_usdExchangeRate)');

      // Fetch latest settings from server with rate-limiting
      await fetchSettingsThrottled();
    } catch (e) {
      debugPrint('[CurrencyService] init error: $e');
    }
  }

  /// Rate-limited fetch from server (strictly max 1 request every 60 seconds)
  Future<void> fetchSettingsThrottled({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastFetchTime != null) {
      final diff = now.difference(_lastFetchTime!);
      if (diff.inSeconds < 60) {
        debugPrint('[CurrencyService] Throttled fetch skipped. Last fetch was ${diff.inSeconds}s ago (Cooldown: 60s). Using cached rate: $_usdExchangeRate');
        return;
      }
    }

    try {
      _lastFetchTime = now;
      debugPrint('[CurrencyService] Fetching fresh currency settings from server...');
      final res = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['success'] == true) {
          final serverDefault = (data['defaultCurrency']?.toString().toUpperCase() == 'USD') ? 'USD' : 'INR';
          final serverRate = double.tryParse(data['usdExchangeRate']?.toString() ?? '85.0') ?? 85.0;

          _adminDefaultCurrency = serverDefault;
          if (serverRate > 0) {
            _usdExchangeRate = serverRate;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(_prefKeyCachedRate, _usdExchangeRate);
          await prefs.setString(_prefKeyCachedAdminDefault, _adminDefaultCurrency);

          // If buyer has NOT set a manual preference, respect Admin's global default!
          if (!_hasUserOverride) {
            _currentCurrency = _adminDefaultCurrency;
            currencyNotifier.value = _currentCurrency;
            debugPrint('[CurrencyService] Updated to Admin default: $_currentCurrency');
          }

          debugPrint('[CurrencyService] Server sync successful: Default=$_adminDefaultCurrency, Rate=$_usdExchangeRate');
        }
      }
    } catch (e) {
      debugPrint('[CurrencyService] fetchSettings error: $e (using cached rate: $_usdExchangeRate)');
    }
  }

  /// Buyer explicitly toggles currency in Buyer App.
  /// Saves to SharedPreferences so it ONLY applies to THIS buyer's device.
  Future<void> toggleCurrency(String newCurrency) async {
    final valid = (newCurrency.toUpperCase() == 'USD') ? 'USD' : 'INR';
    if (_currentCurrency == valid && _hasUserOverride) return;

    _currentCurrency = valid;
    _hasUserOverride = true;
    currencyNotifier.value = valid;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyOverride, valid);
      debugPrint('[CurrencyService] User manually selected: $valid (Saved to Prefs)');
    } catch (e) {
      debugPrint('[CurrencyService] Failed to save pref: $e');
    }

    // Background fetch if 60s passed, otherwise use local cached rate without lagging
    fetchSettingsThrottled(force: false);
  }

  /// Switch toggle helper: flips between INR and USD
  Future<void> switchToggle() async {
    final next = isUSD ? 'INR' : 'USD';
    await toggleCurrency(next);
  }

  /// Convert INR base amount to active currency
  double convertFromINR(double inrAmount) {
    if (isUSD) {
      return inrAmount / (_usdExchangeRate > 0 ? _usdExchangeRate : 85.0);
    }
    return inrAmount;
  }

  /// Format price string with correct currency symbol
  /// Example (Rate 85):
  /// INR: formatPrice(10) -> "₹10.00"
  /// USD: formatPrice(10) -> "$0.12"
  String formatPrice(double inrAmount, {bool showDecimals = true, int decimals = 2}) {
    if (isUSD) {
      final usd = convertFromINR(inrAmount);
      return '\$${usd.toStringAsFixed(decimals)}';
    } else {
      return showDecimals ? '₹${inrAmount.toStringAsFixed(decimals)}' : '₹${inrAmount.toStringAsFixed(0)}';
    }
  }

  /// Helper for Service Rate badge
  /// Example: "$0.12 / review" or "₹10.00 / review"
  String formatRateWithUnit(double inrAmount, String unitName) {
    final formatted = formatPrice(inrAmount, showDecimals: true);
    return '$formatted / ${unitName.toLowerCase()}';
  }
}
