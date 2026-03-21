import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

  /// Format a number without the currency symbol
  /// Example: 100000 -> 100.000
  static String formatNumber(num amount) {
    return NumberFormat.decimalPattern('vi_VN').format(amount);
  }
}

class CurrencyTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Lấy ra các chữ số
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digitsOnly);
    final String newText = CurrencyUtils.formatNumber(number);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
