import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value);
  }
}
