import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;

  // GANTI method initialize() menjadi static
  static Future<void> initialize() async {
    _instance._prefs = await SharedPreferences.getInstance();
  }

  // Atau tetap seperti ini jika ingin instance method
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Printer Settings
  Future<void> setPrinterName(String name) async {
    await _prefs.setString('printer_name', name);
  }

  String? getPrinterNameSync() {
    return _prefs.getString('printer_name');
  }

  Future<void> setPrinterAddress(String address) async {
    await _prefs.setString('printer_address', address);
  }

  String? getPrinterAddressSync() {
    return _prefs.getString('printer_address');
  }

  Future<void> setPrinterType(String type) async {
    await _prefs.setString('printer_type', type);
  }

  String? getPrinterTypeSync() {
    return _prefs.getString('printer_type');
  }

  // Custom Text Settings
  Future<void> setHeaderText(String text) async {
    await _prefs.setString('header_text', text);
  }

  Future<String?> getHeaderText() async {
    return _prefs.getString('header_text');
  }

  Future<void> setFooterText(String text) async {
    await _prefs.setString('footer_text', text);
  }

  Future<String?> getFooterText() async {
    return _prefs.getString('footer_text');
  }

  // Perusahaan Settings
  Future<void> setNamaPerusahaan(String nama) async {
    await _prefs.setString('nama_perusahaan', nama);
  }

  Future<String?> getNamaPerusahaan() async {
    return _prefs.getString('nama_perusahaan');
  }

  Future<void> setAlamatPerusahaan(String alamat) async {
    await _prefs.setString('alamat_perusahaan', alamat);
  }

  Future<String?> getAlamatPerusahaan() async {
    return _prefs.getString('alamat_perusahaan');
  }

  Future<void> setTeleponPerusahaan(String telepon) async {
    await _prefs.setString('telepon_perusahaan', telepon);
  }

  Future<String?> getTeleponPerusahaan() async {
    return _prefs.getString('telepon_perusahaan');
  }

  // Print Settings
  Future<void> setAutoPrint(bool value) async {
    await _prefs.setBool('auto_print', value);
  }

  Future<bool?> getAutoPrint() async {
    return _prefs.getBool('auto_print');
  }

  Future<void> setDuplicatePrint(bool value) async {
    await _prefs.setBool('duplicate_print', value);
  }

  Future<bool?> getDuplicatePrint() async {
    return _prefs.getBool('duplicate_print');
  }

  // Other existing methods...
  Future<void> setPrinterIp(String ip) async {
    await _prefs.setString('printer_ip', ip);
  }

  String? getPrinterIpSync() {
    return _prefs.getString('printer_ip');
  }

  Future<void> setPrinterPort(String port) async {
    await _prefs.setString('printer_port', port);
  }

  String? getPrinterPortSync() {
    return _prefs.getString('printer_port');
  }

  // Tambahkan method untuk catatan kaki
  Future<void> setCatatanKaki(String text) async {
    await _prefs.setString('catatan_kaki', text);
  }

  Future<String?> getCatatanKaki() async {
    return _prefs.getString('catatan_kaki');
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
