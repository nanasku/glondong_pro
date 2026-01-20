// lib/utils/activation_utils.dart
import 'package:flutter/material.dart';

class ActivationUtils {
  // Validasi format kode
  static bool isValidCodeFormat(String code) {
    if (code.isEmpty) return false;

    // Format: AXXXX-BXXXX-CXXXX-DXXXX
    final parts = code.split('-');
    if (parts.length != 4) return false;

    for (var part in parts) {
      if (part.length != 5) return false;
      if (!part.startsWith(RegExp(r'[A-Z]'))) return false;
    }

    return true;
  }

  // Format kode dengan separator
  static String formatActivationCode(String code) {
    if (code.length != 20) return code;

    return '${code.substring(0, 5)}-'
        '${code.substring(5, 10)}-'
        '${code.substring(10, 15)}-'
        '${code.substring(15, 20)}';
  }

  // Mask kode untuk display
  static String maskActivationCode(String code) {
    if (code.length < 8) return code;

    final firstPart = code.substring(0, 4);
    final lastPart = code.substring(code.length - 4);
    return '$firstPart****$lastPart';
  }

  // Generate placeholder device serial
  static String generatePlaceholderSerial() {
    final now = DateTime.now();
    return 'DEV-${now.millisecondsSinceEpoch ~/ 1000}';
  }

  // Check if running in debug mode
  static bool isDebugMode() {
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }
}
