import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _vietnamCurrency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Formats a number to Vietnamese Dong (₫)
  /// Example: 100000 -> 100.000 ₫
  static String format(num? amount) {
    if (amount == null) return "0 ₫";
    return _vietnamCurrency.format(amount);
  }
}
