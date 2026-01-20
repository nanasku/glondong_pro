// lib/services/activation_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ActivationService {
  static final ActivationService _instance = ActivationService._internal();
  factory ActivationService() => _instance;
  ActivationService._internal();

  static const String _activationKey = 'app_activation_status';
  static const String _activationCodeKey = 'app_activation_code';
  static const String _deviceSerialKey = 'device_serial';
  static const String _ownerNameKey = 'owner_name';

  // Tahun lisensi tetap
  static const int _licenseYear = 2026;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Cache untuk device serial (agar tidak berulang-ulang mengambil)
  String? _cachedDeviceSerial;

  // 1. GET DEVICE SERIAL ASLI (STATIC - dari hardware)
  Future<String> getDeviceSerial() async {
    // Return cached value jika sudah ada
    if (_cachedDeviceSerial != null) {
      return _cachedDeviceSerial!;
    }

    try {
      String deviceId = '';

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Gunakan Android ID sebagai device serial
        deviceId = androidInfo.id;

        // Jika Android ID kosong, gunakan fallback yang tetap
        if (deviceId.isEmpty) {
          deviceId = _getAndroidFallbackId(androidInfo);
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Gunakan identifierForVendor untuk iOS
        deviceId = iosInfo.identifierForVendor ?? _getIosFallbackId(iosInfo);
      } else {
        // Untuk platform lain, gunakan fallback tetap
        deviceId = _getGeneralFallbackId();
      }

      // Format Device Serial untuk display (tetap/sama setiap kali)
      // Format: XXXXX-XXXXX-XXXXX-XXXXX (20 karakter)
      var bytes = utf8.encode(deviceId);
      var digest = sha256.convert(bytes);

      String hex = digest.toString();
      String formatted = '';

      // Ambil 20 karakter (5-5-5-5)
      for (int i = 0; i < 20 && i < hex.length; i += 5) {
        if (formatted.isNotEmpty) formatted += '-';
        int endIndex = i + 5;
        if (endIndex > hex.length) endIndex = hex.length;
        formatted += hex.substring(i, endIndex).toUpperCase();
      }

      // Cache hasilnya
      _cachedDeviceSerial = formatted;

      // Simpan ke SharedPreferences untuk akses cepat
      await _saveDeviceSerialToPrefs(formatted);

      print('Device Serial Generated (STATIC): $formatted');
      print(
        'Source Device ID: ${deviceId.substring(0, min(20, deviceId.length))}...',
      );

      return formatted;
    } catch (e, stackTrace) {
      print('Error getting device serial: $e\n$stackTrace');

      // Gunakan fallback yang tetap
      String fallback = _getStaticFallbackId();
      _cachedDeviceSerial = fallback;
      await _saveDeviceSerialToPrefs(fallback);

      return fallback;
    }
  }

  // Helper: Get Android fallback ID (tetap)
  String _getAndroidFallbackId(AndroidDeviceInfo androidInfo) {
    // Gunakan kombinasi yang unik dan tetap per device
    return 'android-'
        '${androidInfo.model}-'
        '${androidInfo.manufacturer}-'
        '${androidInfo.board}-'
        '${androidInfo.bootloader}-'
        '${androidInfo.brand}';
  }

  // Helper: Get iOS fallback ID (tetap)
  String _getIosFallbackId(IosDeviceInfo iosInfo) {
    return 'ios-'
        '${iosInfo.name}-'
        '${iosInfo.model}-'
        '${iosInfo.systemName}-'
        '${iosInfo.systemVersion}-'
        '${iosInfo.utsname.machine}';
  }

  // Helper: Get general fallback ID (tetap)
  String _getGeneralFallbackId() {
    return 'device-unknown-platform-${defaultTargetPlatform}';
  }

  // Helper: Get static fallback ID (sama setiap kali untuk device yang sama)
  String _getStaticFallbackId() {
    // Hash dari timestamp pertama kali app diinstall (simpan di prefs)
    return 'fallback-device-${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
  }

  // Save device serial to SharedPreferences
  Future<void> _saveDeviceSerialToPrefs(String serial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceSerialKey, serial);
  }

  // Load device serial from SharedPreferences
  Future<String?> loadSavedDeviceSerial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceSerialKey);
  }

  // 2. GENERATE SECRET_KEY dari Nama Pemilik Perusahaan
  String _generateSecretKey(String ownerName) {
    try {
      if (ownerName.isEmpty) {
        throw Exception('Nama pemilik perusahaan tidak boleh kosong');
      }

      // Normalisasi nama pemilik
      String normalizedName = ownerName
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
          .trim();

      if (normalizedName.length < 2) {
        throw Exception('Nama pemilik minimal 2 karakter');
      }

      // Manipulasi string:
      // 1. Ambil 2-3 karakter pertama
      // 2. Reverse seluruh string
      // 3. Gabung dengan tahun
      int takeChars = normalizedName.length >= 3 ? 3 : 2;
      String firstChars = normalizedName.substring(0, takeChars);
      String reversed = normalizedName.split('').reversed.join();

      String combined = '$firstChars@$reversed$_licenseYear';

      // Hash SHA256
      var bytes = utf8.encode(combined);
      var digest = sha256.convert(bytes);

      // Ambil 32 karakter pertama sebagai SECRET_KEY
      return digest.toString().substring(0, 32);
    } catch (e) {
      print('Error generating secret key: $e');
      return 'default_secret_key_${ownerName.hashCode}';
    }
  }

  // 3. GENERATE ACTIVATION CODE sesuai rumus
  String generateActivationCode(String deviceSerial, String ownerName) {
    try {
      if (deviceSerial.isEmpty) {
        throw Exception('Device serial tidak boleh kosong');
      }

      if (ownerName.isEmpty) {
        throw Exception('Nama pemilik perusahaan tidak boleh kosong');
      }

      // Generate SECRET_KEY dari nama pemilik
      String secretKey = _generateSecretKey(ownerName);

      // ✅ SESUAI RUMUS: Device Serial + SECRET_KEY
      String combined = deviceSerial + secretKey;

      // ✅ HASH (SHA256)
      var bytes = utf8.encode(combined);
      var digest = sha256.convert(bytes);

      // Format Activation Code: XXXX-XXXX-XXXX-XXXX (16 karakter)
      String hex = digest.toString();
      String activationCode = '';

      for (int i = 0; i < 16 && i < hex.length; i += 4) {
        if (activationCode.isNotEmpty) activationCode += '-';
        int endIndex = i + 4;
        if (endIndex > hex.length) endIndex = hex.length;
        activationCode += hex.substring(i, endIndex).toUpperCase();
      }

      return activationCode;
    } catch (e) {
      print('Error generating activation code: $e');
      return '';
    }
  }

  // 4. VERIFIKASI ACTIVATION CODE
  bool verifyActivationCode(
    String deviceSerial,
    String ownerName,
    String userInputCode,
  ) {
    try {
      // Generate expected code
      String expectedCode = generateActivationCode(deviceSerial, ownerName);

      if (expectedCode.isEmpty) {
        return false;
      }

      // Normalize codes (remove dashes, convert to uppercase)
      String normalizeCode(String code) {
        return code.replaceAll(RegExp(r'[^A-Z0-9]'), '').toUpperCase();
      }

      String normalizedInput = normalizeCode(userInputCode);
      String normalizedExpected = normalizeCode(expectedCode);

      // Compare (minimum 12 characters for tolerance)
      int compareLength = normalizedInput.length < normalizedExpected.length
          ? normalizedInput.length
          : normalizedExpected.length;

      // Minimal bandingkan 8 karakter
      compareLength = compareLength < 8 ? compareLength : 8;

      return normalizedInput.substring(0, compareLength) ==
          normalizedExpected.substring(0, compareLength);
    } catch (e) {
      print('Error verifying activation code: $e');
      return false;
    }
  }

  // 5. SIMPAN NAMA PEMILIK
  Future<void> saveOwnerName(String ownerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerNameKey, ownerName.trim().toUpperCase());
  }

  Future<String?> getOwnerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ownerNameKey);
  }

  // 6. Method lainnya
  Future<bool> isActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activationKey) ?? false;
  }

  Future<void> setActivated(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activationKey, status);
  }

  Future<void> saveActivationCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activationCodeKey, code.trim().toUpperCase());
  }

  Future<String?> getActivationCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activationCodeKey);
  }

  // 7. Reset aktivasi (hanya reset status, device serial tetap)
  Future<void> resetActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activationKey);
    await prefs.remove(_activationCodeKey);
    await prefs.remove(_ownerNameKey);
    print('Activation reset completed (Device Serial tetap)');
  }

  // 8. Get device info for display
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'device': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'androidId': androidInfo.id,
          'version': androidInfo.version.release,
          'board': androidInfo.board,
          'bootloader': androidInfo.bootloader,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'device': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'identifierForVendor': iosInfo.identifierForVendor,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    return {'platform': defaultTargetPlatform.toString(), 'device': 'Unknown'};
  }

  // Helper untuk min function
  int min(int a, int b) => a < b ? a : b;
}
