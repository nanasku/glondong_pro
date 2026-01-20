import 'package:intl/intl.dart';

class Formatter {
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatCurrency(int amount) {
    return currencyFormat.format(amount);
  }

  static String formatNumber(int number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
