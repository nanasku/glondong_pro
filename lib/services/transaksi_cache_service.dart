import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransaksiCacheService {
  static const String _pembelianCacheKey = 'cached_pembelian_transaction';
  static const String _penjualanCacheKey = 'cached_penjualan_transaction';
  static const int _cacheMaxAgeHours = 24; // Cache berlaku 24 jam

  // Simpan cache transaksi pembelian
  Future<void> cachePembelian(Map<String, dynamic> transactionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        ...transactionData,
        'cacheType': 'pembelian',
        'cachedAt': DateTime.now().toIso8601String(),
      };
      final jsonString = _mapToJsonString(cacheData);
      await prefs.setString(_pembelianCacheKey, jsonString);
    } catch (e) {
      print('Error caching pembelian: $e');
    }
  }

  // Ambil cache transaksi pembelian
  Future<Map<String, dynamic>?> getCachedPembelian() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pembelianCacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final cacheData = _jsonStringToMap(jsonString);

      // Cek usia cache (jangan gunakan cache yang terlalu lama)
      final cachedAt = cacheData['cachedAt'];
      if (cachedAt != null) {
        final cacheTime = DateTime.parse(cachedAt);
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference.inHours > _cacheMaxAgeHours) {
          // Hapus cache yang sudah expired
          await clearPembelianCache();
          return null;
        }
      }

      return cacheData;
    } catch (e) {
      print('Error getting cached pembelian: $e');
      return null;
    }
  }

  // Hapus cache transaksi pembelian
  Future<void> clearPembelianCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pembelianCacheKey);
    } catch (e) {
      print('Error clearing pembelian cache: $e');
    }
  }

  // Simpan cache transaksi penjualan
  Future<void> cachePenjualan(Map<String, dynamic> transactionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        ...transactionData,
        'cacheType': 'penjualan',
        'cachedAt': DateTime.now().toIso8601String(),
      };
      final jsonString = _mapToJsonString(cacheData);
      await prefs.setString(_penjualanCacheKey, jsonString);
    } catch (e) {
      print('Error caching penjualan: $e');
    }
  }

  // Ambil cache transaksi penjualan
  Future<Map<String, dynamic>?> getCachedPenjualan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_penjualanCacheKey);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final cacheData = _jsonStringToMap(jsonString);

      // Cek usia cache
      final cachedAt = cacheData['cachedAt'];
      if (cachedAt != null) {
        final cacheTime = DateTime.parse(cachedAt);
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference.inHours > _cacheMaxAgeHours) {
          await clearPenjualanCache();
          return null;
        }
      }

      return cacheData;
    } catch (e) {
      print('Error getting cached penjualan: $e');
      return null;
    }
  }

  // Hapus cache transaksi penjualan
  Future<void> clearPenjualanCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_penjualanCacheKey);
    } catch (e) {
      print('Error clearing penjualan cache: $e');
    }
  }

  // Hapus semua cache
  Future<void> clearAllCache() async {
    await clearPembelianCache();
    await clearPenjualanCache();
  }

  // Helper functions untuk konversi Map <-> JSON String
  String _mapToJsonString(Map<String, dynamic> map) {
    // Convert semua value ke string representation
    final convertedMap = map.map((key, value) {
      if (value is List) {
        // Convert list items
        final List<dynamic> convertedList = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _mapToJsonString(item);
          }
          return item.toString();
        }).toList();
        return MapEntry(key, convertedList);
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _mapToJsonString(value));
      }
      return MapEntry(key, value.toString());
    });

    return convertedMap.toString();
  }

  Map<String, dynamic> _jsonStringToMap(String jsonString) {
    try {
      // Parse string representation kembali ke Map
      final Map<String, dynamic> result = {};

      // Remove curly braces
      String content = jsonString.substring(1, jsonString.length - 1);

      // Parse key-value pairs
      List<String> pairs = content.split(', ');
      for (String pair in pairs) {
        List<String> keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          String key = keyValue[0].trim();
          String value = keyValue[1].trim();

          // Handle nested maps
          if (value.startsWith('{') && value.endsWith('}')) {
            result[key] = _jsonStringToMap(value);
          }
          // Handle lists
          else if (value.startsWith('[') && value.endsWith(']')) {
            result[key] = _parseList(value);
          }
          // Handle simple values
          else {
            result[key] = value;
          }
        }
      }

      return result;
    } catch (e) {
      print('Error parsing JSON string: $e');
      return {};
    }
  }

  List<dynamic> _parseList(String listString) {
    try {
      // Remove brackets
      String content = listString.substring(1, listString.length - 1);
      if (content.isEmpty) return [];

      List<String> items = content.split(', ');
      return items.map((item) {
        if (item.startsWith('{') && item.endsWith('}')) {
          return _jsonStringToMap(item);
        }
        return item;
      }).toList();
    } catch (e) {
      print('Error parsing list: $e');
      return [];
    }
  }
}
