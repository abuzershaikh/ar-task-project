import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _currencyFormatWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount) {
    return _currencyFormat.format(amount);
  }

  static String formatWithDecimals(num amount) {
    return _currencyFormatWithDecimals.format(amount);
  }

  static String formatCompact(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }

  static String formatWithSign(num amount) {
    final formatted = format(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }
}
