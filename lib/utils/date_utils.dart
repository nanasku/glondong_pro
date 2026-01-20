import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String getCurrentDate() {
    return formatDate(DateTime.now());
  }

  static String getCurrentDateTime() {
    return formatDateTime(DateTime.now());
  }

  static String generateFaktur(String prefix) {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(now);
    final timePart = DateFormat('HHmmss').format(now);
    return '$prefix$datePart$timePart';
  }
}
