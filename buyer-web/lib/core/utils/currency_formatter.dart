import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format amount in INR with symbol
  /// Example: formatINR(1000) => ₹1,000
  static String formatINR(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrFormatterWithDecimals.format(amount);
    }
    return _inrFormatter.format(amount);
  }

  /// Format amount in compact form (K, L, Cr)
  /// Example: formatCompact(150000) => ₹1.5L
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      // Crores
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      // Lakhs
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      // Thousands
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  /// Format amount with + or - sign
  /// Example: formatWithSign(1000, true) => +₹1,000
  static String formatWithSign(double amount, bool isPositive) {
    final formatted = formatINR(amount.abs());
    return isPositive ? '+$formatted' : '−$formatted';
  }
}
