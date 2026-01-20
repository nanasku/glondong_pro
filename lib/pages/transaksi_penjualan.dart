import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tpk_app/pages/pengaturan_page.dart';
import 'package:tpk_app/services/database_service.dart';
import 'package:tpk_app/services/preferences_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'pengaturan_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransaksiPenjualan extends StatefulWidget {
  const TransaksiPenjualan({super.key});

  @override
  _TransaksiPenjualanState createState() => _TransaksiPenjualanState();
}

class _TransaksiPenjualanState extends State<TransaksiPenjualan>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Ini akan menjaga state saat pindah halaman

  String? selectedCustomKriteria;
  bool modalVisible = false;
  String noFaktur = '';
  String pembeli = '';
  String alamat = '';
  String kayu = '';

  Map<String, dynamic> harga = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  String kriteria = '';
  String diameter = '';
  String panjang = '';
  List<Map<String, dynamic>> data = [];
  String? latestItemId;

  List<Map<String, dynamic>> customVolumes = [];
  String customDiameter = '';
  String customVolumeValue = '';

  ScrollController _scrollController = ScrollController();
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefs =
      PreferencesService(); // Tetap untuk ambil settings

  // Data dari database SQLite
  List<Map<String, dynamic>> daftarPembeli = [];
  List<Map<String, dynamic>> daftarKayu = [];
  String? selectedPembeliId;
  String? selectedKayuId;
  String? selectedPembeliNama;
  String? selectedPembeliAlamat;
  String? selectedKayuNama;

  // Variabel untuk operasional
  List<Map<String, dynamic>> operasionals = [];
  TextEditingController operasionalJenisController = TextEditingController();
  TextEditingController operasionalBiayaController = TextEditingController();
  String operasionalTipe = 'tambah';

  // TextEditingController
  TextEditingController diameterController = TextEditingController();
  TextEditingController panjangController = TextEditingController();
  TextEditingController customDiameterController = TextEditingController();
  TextEditingController customVolumeController = TextEditingController();

  // Formatter untuk currency
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeDatabase();
    // Coba muat data dari cache/shared preferences jika ada
    _loadSavedTransaction();
  }

  Future<void> _initializeDatabase() async {
    await _dbService.initializeDatabase();
    getNoFakturBaru();
    _loadDataDariDatabase();
  }

  @override
  void dispose() {
    // Simpan transaksi yang sedang berlangsung sebelum dispose
    if (data.isNotEmpty) {
      _saveCurrentTransaction();
    }

    diameterController.dispose();
    panjangController.dispose();
    customDiameterController.dispose();
    customVolumeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Modifikasi fungsi resetForm untuk juga menghapus cache
  void resetForm() {
    setState(() {
      panjangController.clear();
      diameterController.clear();
      customDiameterController.clear();
      customVolumeController.clear();
      operasionalJenisController.clear();
      operasionalBiayaController.clear();

      selectedCustomKriteria = null;
      selectedPembeliId = null;
      selectedPembeliNama = null;
      selectedPembeliAlamat = null;
      selectedKayuId = null;
      selectedKayuNama = null;

      pembeli = '';
      alamat = '';
      kayu = '';
      diameter = '';
      panjang = '';
      customDiameter = '';
      customVolumeValue = '';
      operasionalTipe = 'tambah';

      data.clear();
      operasionals.clear();
      customVolumes.clear();
      harga = {
        'Rijek 1': 0.0,
        'Rijek 2': 0.0,
        'Standar': 0.0,
        'Super A': 0.0,
        'Super B': 0.0,
        'Super C': 0.0,
      };
      modalVisible = false;
    });

    getNoFakturBaru();
    _clearSavedTransaction(); // Hapus cache saat reset
  }

  double get totalVolume {
    return data.fold(0, (sum, item) => sum + (item['volume'] * item['jumlah']));
  }

  double get totalHarga {
    return data.fold(0, (sum, item) => sum + item['jumlahHarga']);
  }

  // Fungsi untuk memuat data dari database SQLite
  Future<void> _loadDataDariDatabase() async {
    await _loadPembeli();
    await _loadKayu();
  }

  // Fungsi untuk memuat data penjual dari SQLite
  Future<void> _loadPembeli() async {
    try {
      final pembeliData = await _dbService.getAllPembeli();
      setState(() {
        daftarPembeli = pembeliData
            .map(
              (item) => {
                'id': item['id'].toString(),
                'nama': item['nama'] ?? '',
                'alamat': item['alamat'] ?? '',
                'telepon': item['telepon'] ?? '',
                'email': item['email'] ?? '',
              },
            )
            .toList();
      });
    } catch (error) {
      print('Error loading pembeli: $error');
    }
  }

  // Fungsi untuk memuat data kayu dari SQLite
  Future<void> _loadKayu() async {
    try {
      final kayuData = await _dbService.getAllHargaJual();
      setState(() {
        daftarKayu = kayuData
            .map(
              (item) => {
                'id': item['id'].toString(),
                'nama_kayu': item['nama_kayu'] ?? '',
                'harga_rijek_1': item['harga_rijek_1'] ?? 0,
                'harga_rijek_2': item['harga_rijek_2'] ?? 0,
                'harga_standar': item['harga_standar'] ?? 0,
                'harga_super_a': item['harga_super_a'] ?? 0,
                'harga_super_b': item['harga_super_b'] ?? 0,
                'harga_super_c': item['harga_super_c'] ?? 0,
              },
            )
            .toList();
      });
    } catch (error) {
      print('Error loading kayu: $error');
    }
  }

  // Generate nomor faktur baru
  Future<void> getNoFakturBaru() async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('ddMMyy').format(now);

      final db = await _dbService.database;
      final lastFaktur = await db.query(
        'penjualan',
        where: 'faktur_penj LIKE ?',
        whereArgs: ['PJ$dateStr%'],
        orderBy: 'id DESC',
        limit: 1,
      );

      int nextNumber = 1;
      if (lastFaktur.isNotEmpty) {
        final lastFakturStr = lastFaktur.first['faktur_penj'] as String;
        final lastNum = int.tryParse(lastFakturStr.substring(8)) ?? 0;
        nextNumber = lastNum + 1;
      }

      setState(() {
        noFaktur = 'PJ${dateStr}${nextNumber.toString().padLeft(3, '0')}';
      });
    } catch (e) {
      setState(() {
        noFaktur = 'PJ${DateFormat('ddMMyy').format(DateTime.now())}001';
      });
    }
  }

  void handleAddOrUpdate() {
    if (diameter.isEmpty || panjang.isEmpty) return;

    double d = double.tryParse(diameter) ?? 0;
    double p = double.tryParse(panjang) ?? 0;
    if (d == 0 || p == 0) return;

    String currentKriteria = selectedCustomKriteria ?? '';
    if (currentKriteria.isEmpty) {
      if (d >= 10 && d <= 14) {
        currentKriteria = 'Rijek 1';
      } else if (d >= 15 && d <= 19) {
        currentKriteria = 'Rijek 2';
      } else if (d >= 20 && d <= 24) {
        currentKriteria = 'Standar';
      } else if (d >= 25) {
        currentKriteria = 'Super C';
      }
    }

    // Normalisasi label
    String normalizeKriteria(String label) {
      switch (label) {
        case 'R1':
          return 'Rijek 1';
        case 'R2':
          return 'Rijek 2';
        case 'St':
          return 'Standar';
        case 'Sp A':
          return 'Super A';
        case 'Sp B':
          return 'Super B';
        case 'Sp C':
          return 'Super C';
        default:
          return label;
      }
    }

    currentKriteria = normalizeKriteria(currentKriteria);

    dynamic rawHarga = harga[currentKriteria];
    double hargaDouble = 0;

    if (rawHarga is String) {
      hargaDouble = double.tryParse(rawHarga) ?? 0;
    } else if (rawHarga is int) {
      hargaDouble = rawHarga.toDouble();
    } else if (rawHarga is double) {
      hargaDouble = rawHarga;
    } else {
      hargaDouble = 0;
    }

    int hargaSatuan = hargaDouble.round();
    if (hargaSatuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga tidak ditemukan untuk grade $currentKriteria'),
        ),
      );
      return;
    }

    // Hitung volume
    var custom = customVolumes.firstWhere(
      (c) => c['diameter'] == d,
      orElse: () => {},
    );

    double volume;
    if (custom.isNotEmpty) {
      var rawVol = custom['volume'];
      if (rawVol is int) {
        volume = rawVol.toDouble();
      } else if (rawVol is double) {
        volume = rawVol;
      } else if (rawVol is String) {
        volume = double.tryParse(rawVol) ?? 0;
      } else {
        volume = 0;
      }
    } else {
      double rawVolume = (0.785 * d * d * p) / 1000;
      double decimal = rawVolume - rawVolume.floor();
      volume = (decimal >= 0.6 ? rawVolume.floor() + 1 : rawVolume.floor())
          .toDouble();
    }

    // Hitung total harga
    int jumlahHarga = (volume * hargaSatuan).round();

    // Cek duplikasi
    int existingIndex = data.indexWhere(
      (item) =>
          item['diameter'] == d &&
          item['panjang'] == p &&
          item['kriteria'] == currentKriteria,
    );

    List<Map<String, dynamic>> updatedData;
    if (existingIndex >= 0) {
      updatedData = List<Map<String, dynamic>>.from(data);
      var item = updatedData[existingIndex];
      int newJumlah = item['jumlah'] + 1;
      updatedData[existingIndex] = {
        ...item,
        'jumlah': newJumlah,
        'jumlahHarga': (volume * hargaSatuan * newJumlah).round(),
      };
      updatedData = sortData(updatedData);
      setState(() {
        latestItemId = updatedData[existingIndex]['id'];
        data = updatedData;
      });
    } else {
      var newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'kriteria': currentKriteria,
        'diameter': d,
        'panjang': p,
        'jumlah': 1,
        'volume': volume,
        'harga': hargaSatuan,
        'jumlahHarga': jumlahHarga,
      };
      updatedData = sortData([...data, newItem]);
      setState(() {
        latestItemId = newItem['id'].toString();
        data = updatedData;
      });
    }

    // Scroll ke bawah
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, dynamic>> sortData(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      if (a['kriteria'] != b['kriteria']) {
        return a['kriteria'].compareTo(b['kriteria']);
      }
      if (a['diameter'] != b['diameter']) {
        return a['diameter'].compareTo(b['diameter']);
      }
      return a['panjang'].compareTo(b['panjang']);
    });
    return list;
  }

  String getShortLabel(String kriteria) {
    switch (kriteria) {
      case 'Rijek 1':
        return 'R 1';
      case 'Rijek 2':
        return 'R 2';
      case 'Standar':
        return 'St';
      case 'Super A':
        return 'Sp A';
      case 'Super B':
        return 'Sp B';
      case 'Super C':
        return 'Sp C';
      default:
        return kriteria;
    }
  }

  void updateJumlah(String id, int delta) {
    setState(() {
      data = sortData(
        data.map((item) {
          if (item['id'] == id) {
            int jumlah = (item['jumlah'] + delta).clamp(1, 999999);
            return {
              ...item,
              'jumlah': jumlah,
              'jumlahHarga': item['volume'] * item['harga'] * jumlah,
            };
          }
          return item;
        }).toList(),
      );
    });
  }

  void handleDecrement(String id) {
    setState(() {
      int index = data.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        var item = data[index];
        if (item['jumlah'] <= 1) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Konfirmasi Hapus'),
                content: Text('Apakah Anda yakin ingin menghapus item ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        data.removeWhere((i) => i['id'] == id);
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              );
            },
          );
        } else {
          item['jumlah'] -= 1;
          item['jumlahHarga'] = item['volume'] * item['jumlah'] * item['harga'];
          data = sortData(List.from(data));
        }
      }
    });
  }

  // Di fungsi _loadSavedTransaction(), tambahkan:
  Future<void> _loadSavedTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('current_penjualan_transaction');

      if (savedData != null && savedData.isNotEmpty) {
        print('=== LOADING SAVED TRANSACTION ===');
        print('Raw data length: ${savedData.length}');

        final transactionData = json.decode(savedData) as Map<String, dynamic>;

        setState(() {
          noFaktur = transactionData['noFaktur'] ?? noFaktur;
          pembeli = transactionData['pembeli'] ?? '';
          alamat = transactionData['alamat'] ?? '';
          kayu = transactionData['kayu'] ?? '';
          selectedPembeliId = transactionData['selectedPembeliId'];
          selectedPembeliNama = transactionData['selectedPembeliNama'];
          selectedPembeliAlamat = transactionData['selectedPembeliAlamat'];
          selectedKayuId = transactionData['selectedKayuId'];
          selectedKayuNama = transactionData['selectedKayuNama'];

          // Pastikan data di-decode dengan benar
          data =
              (transactionData['data'] as List<dynamic>?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              [];

          operasionals =
              (transactionData['operasionals'] as List<dynamic>?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              [];

          customVolumes =
              (transactionData['customVolumes'] as List<dynamic>?)
                  ?.map((item) => Map<String, dynamic>.from(item))
                  .toList() ??
              [];

          harga = Map<String, dynamic>.from(transactionData['harga'] ?? {});
          modalVisible = transactionData['modalVisible'] ?? false;
          selectedCustomKriteria = transactionData['selectedCustomKriteria'];
          diameter = transactionData['diameter'] ?? '';
          panjang = transactionData['panjang'] ?? '';
          customDiameter = transactionData['customDiameter'] ?? '';
          customVolumeValue = transactionData['customVolumeValue'] ?? '';
          operasionalTipe = transactionData['operasionalTipe'] ?? 'tambah';

          // Set nilai controller
          diameterController.text = diameter;
          panjangController.text = panjang;
          customDiameterController.text = customDiameter;
          customVolumeController.text = customVolumeValue;
        });

        print('Loaded data items: ${data.length}');
        print('Loaded operasionals: ${operasionals.length}');
        for (var op in operasionals) {
          print('- ${op['jenis']}: ${op['biaya']} (${op['tipe']})');
        }
        print('=====================');
      } else {
        print('No saved transaction found');
      }
    } catch (e) {
      print('Error loading saved transaction: $e');
      print('Error details: ${e.toString()}');
    }
  }

  // Fungsi untuk menghapus transaksi yang tersimpan (saat selesai)
  Future<void> _clearSavedTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_penjualan_transaction');
  }

  // FUNGSI UTAMA: Simpan dan Cetak
  Future<void> _handleSimpanTransaksi() async {
    try {
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data transaksi untuk disimpan')),
        );
        return;
      }

      if (selectedPembeliId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih pembeli terlebih dahulu')),
        );
        return;
      }

      if (selectedKayuId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih jenis kayu terlebih dahulu')),
        );
        return;
      }

      // Simpan ke database dulu
      bool saveSuccess = await _simpanKeDatabase();

      if (!saveSuccess) {
        return; // Jika gagal simpan, jangan lanjut
      }

      // Tanya apakah mau cetak
      bool? confirmPrint = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cetak Struk'),
            content: Text('Apakah Anda ingin mencetak struk penjualan?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                  resetForm();
                },
                child: Text('Tidak'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Ya, Cetak'),
              ),
            ],
          );
        },
      );

      if (confirmPrint == true) {
        await _cetakStrukLangsung();
      } else {
        resetForm();
      }
    } catch (e) {
      print('Error in _handleSimpanTransaksi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Tambahkan ini untuk menyimpan state saat pindah halaman
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Simpan state secara periodik atau saat ada perubahan data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (data.isNotEmpty) {
        _saveCurrentTransaction();
      }
    });
  }

  // Fungsi untuk menyimpan ke database SQLite
  Future<bool> _simpanKeDatabase() async {
    try {
      final db = await _dbService.database;

      // Hitung total harga
      double totalHarga = data.fold<double>(
        0.0,
        (sum, item) => sum + (item['jumlahHarga'] as num).toDouble(),
      );

      // Hitung total operasional
      double totalOperasional = 0.0;
      for (var op in operasionals) {
        final biaya = (op['biaya'] as num).toDouble();
        if (op['tipe'] == 'tambah') {
          totalOperasional += biaya;
        } else {
          totalOperasional -= biaya;
        }
      }

      double totalAkhir = totalHarga + totalOperasional;

      // Mulai transaction
      await db.transaction((txn) async {
        // 1. Insert ke tabel penjualan
        await txn.insert('penjualan', {
          'faktur_penj': noFaktur,
          'pembeli_id': int.tryParse(selectedPembeliId ?? '0'),
          'product_id': int.tryParse(selectedKayuId ?? '0'),
          'total': totalAkhir.round(),
          'created_at': DateTime.now().toIso8601String(),
        });

        // 2. Insert detail penjualan
        for (var item in data) {
          await txn.insert('penjualan_detail', {
            'faktur_penj': noFaktur,
            'nama_kayu': kayu,
            'kriteria': item['kriteria'],
            'diameter': item['diameter'],
            'panjang': item['panjang'],
            'jumlah': item['jumlah'],
            'volume': item['volume'],
            'harga_jual': item['harga'],
            'jumlah_harga_jual': item['jumlahHarga'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // 3. Insert operasional jika ada
        for (var op in operasionals) {
          await txn.insert('penjualan_operasional', {
            'faktur_penj': noFaktur,
            'jenis': op['jenis'],
            'biaya': op['biaya'],
            'tipe': op['tipe'],
          });
        }

        // 4. Update stok
        for (var item in data) {
          final existingStok = await txn.query(
            'stok',
            where:
                'nama_kayu = ? AND kriteria = ? AND diameter = ? AND panjang = ?',
            whereArgs: [
              kayu,
              item['kriteria'],
              item['diameter'],
              item['panjang'],
            ],
          );

          if (existingStok.isNotEmpty) {
            final currentStok = existingStok.first['stok_buku'] as int;
            await txn.update(
              'stok',
              {
                'stok_buku': currentStok + item['jumlah'],
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [existingStok.first['id']],
            );
          } else {
            await txn.insert('stok', {
              'nama_kayu': kayu,
              'kriteria': item['kriteria'],
              'diameter': item['diameter'],
              'panjang': item['panjang'],
              'stok_buku': item['jumlah'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Transaksi berhasil disimpan')));

      return true; // Berhasil
    } catch (error) {
      print('Error menyimpan transaksi: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi')));

      return false; // Gagal
    }
  }

  // FUNGSI CETAK yang mengambil setting dari Preferences
  Future<void> _cetakStrukLangsung() async {
    try {
      // Ambil pengaturan dari Preferences
      final printerName = _prefs.getPrinterNameSync();
      final printerAddress = _prefs.getPrinterAddressSync();
      final footerText = await _prefs.getFooterText() ?? 'TERIMA KASIH';
      final namaPerusahaan = await _prefs.getNamaPerusahaan() ?? '';
      final alamatPerusahaan = await _prefs.getAlamatPerusahaan() ?? '';
      final teleponPerusahaan = await _prefs.getTeleponPerusahaan() ?? '';
      final autoPrint = await _prefs.getAutoPrint() ?? false;
      final duplicatePrint = await _prefs.getDuplicatePrint() ?? false;

      // Cek permission Bluetooth terlebih dahulu
      bool hasPermission = await _checkBluetoothPermissions();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Izin Bluetooth diperlukan untuk mencetak'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Buat instance printer
      final printer = BlueThermalPrinter.instance;

      // Cari printer yang sesuai
      List<BluetoothDevice> devices = await printer.getBondedDevices();
      BluetoothDevice? targetDevice;

      for (var device in devices) {
        if (device.name == printerName && device.address == printerAddress) {
          targetDevice = device;
          break;
        }
      }

      if (targetDevice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Printer "${printerName}" tidak ditemukan. Silakan periksa koneksi Bluetooth.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Tampilkan indikator loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menghubungkan ke printer...'),
            ],
          ),
        ),
      );

      try {
        // Cek status koneksi saat ini
        bool? isConnected = await printer.isConnected;

        // Jika sudah terhubung ke device lain, putuskan dulu
        if (isConnected == true) {
          await printer.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
        }

        // Coba koneksi ke printer
        await printer.connect(targetDevice);

        // Tunggu sebentar untuk koneksi stabil
        await Future.delayed(Duration(milliseconds: 1500));

        // Verifikasi koneksi
        isConnected = await printer.isConnected;

        if (isConnected != true) {
          Navigator.pop(context); // Tutup dialog loading
          throw Exception(
            'Gagal terhubung ke printer. Pastikan printer dalam keadaan ON dan sudah dipasangkan (paired).',
          );
        }

        Navigator.pop(context); // Tutup dialog loading setelah terhubung

        // Tampilkan pesan sedang mencetak
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sedang mencetak struk...'),
            backgroundColor: Colors.blue,
          ),
        );

        // Reset printer
        await printer.printNewLine();

        // HEADER PERUSAHAAN
        if (namaPerusahaan.isNotEmpty) {
          await printer.printCustom(namaPerusahaan, 3, 1);
        }

        if (alamatPerusahaan.isNotEmpty) {
          await printer.printCustom(alamatPerusahaan, 0, 1);
        }

        if (teleponPerusahaan.isNotEmpty) {
          await printer.printCustom('Telp: $teleponPerusahaan', 0, 1);
        }

        await printer.printCustom('========================', 1, 1);

        // INFORMASI TRANSAKSI
        int lineWidth = 32;

        String noFakturLine =
            'No Faktur'.padRight(lineWidth - noFaktur.length) + noFaktur;
        await printer.printCustom(noFakturLine, 1, 0);

        String tanggalLine =
            'Tanggal'.padRight(
              lineWidth -
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()).length,
            ) +
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        await printer.printCustom(tanggalLine, 1, 0);

        String pembeliLine =
            'Pembeli'.padRight(lineWidth - pembeli.length) + pembeli;
        await printer.printCustom(pembeliLine, 1, 0);

        String kayuLine = 'Kayu'.padRight(lineWidth - kayu.length) + kayu;
        await printer.printCustom(kayuLine, 1, 0);

        await printer.printCustom('------------------------', 1, 1);

        // DETAIL ITEM
        for (var item in data) {
          String kriteria = getShortLabel(item['kriteria']);
          int diameter = item['diameter'].toInt();
          int panjang = item['panjang'].toInt();
          int jumlah = item['jumlah'];
          int volume = item['volume'].toInt();
          int totalVolume = (volume * jumlah).toInt();
          int harga = item['harga'];
          int jumlahHarga = item['jumlahHarga'];

          // BARIS 1
          String kiriHeader = '$kriteria D$diameter P$panjang';
          String kananHeader = '$jumlah x $volume cm3';
          await printer.printLeftRight(kiriHeader, kananHeader, 1);

          // BARIS 2
          String detail =
              '$totalVolume cm3 x ${formatter.format(harga)} = ${formatter.format(jumlahHarga)}';
          await printer.printCustom(
            detail,
            1,
            2,
          ); // 1 = ukuran normal, 2 = kanan
          await printer.printNewLine();
        }

        await printer.printCustom('------------------------', 1, 1);

        // TOTAL VOLUME & HARGA
        double totalVol = data.fold(
          0,
          (sum, item) => sum + (item['volume'] * item['jumlah']),
        );
        await printer.printLeftRight(
          'Total Volume',
          '${totalVol.toStringAsFixed(0)} cm3',
          1,
        );

        double totalHrg = data.fold(
          0,
          (sum, item) => sum + item['jumlahHarga'],
        );
        await printer.printLeftRight(
          'Total Harga',
          formatter.format(totalHrg),
          1,
        );

        // DEBUG: Cek operasional sebelum cetak
        print('=== DEBUG SEBELUM CETAK ===');
        print('Operasionals count: ${operasionals.length}');
        print('Operasionals: $operasionals');

        for (var i = 0; i < operasionals.length; i++) {
          var op = operasionals[i];
          print(
            'Operasional $i: ${op['jenis']} - ${op['biaya']} (${op['tipe']})',
          );
        }
        print('==========================');

        // BIAYA OPERASIONAL
        if (operasionals.isNotEmpty) {
          print('Operasionals ditemukan, mencetak...');
          await printer.printCustom('------------------------', 1, 1);
          await printer.printCustom('BIAYA OPERASIONAL:', 1, 0);

          for (var op in operasionals) {
            String jenis = op['jenis'].toString();
            int biaya = int.tryParse(op['biaya'].toString()) ?? 0;
            String tipe = op['tipe'].toString();
            String symbol = tipe == 'tambah' ? '+' : '-';

            print('Mencetak: $symbol $jenis - ${formatter.format(biaya)}');

            await printer.printLeftRight(
              '$symbol $jenis',
              formatter.format(biaya),
              0,
            );
          }

          // Hitung total operasional
          double totalOperasional = 0.0;
          for (var op in operasionals) {
            final biaya = (int.tryParse(op['biaya'].toString()) ?? 0)
                .toDouble();
            if (op['tipe'] == 'tambah') {
              totalOperasional += biaya;
            } else {
              totalOperasional -= biaya;
            }
          }

          String totalOpStr = formatter.format(totalOperasional);
          // Pastikan tidak ada newline atau spasi aneh
          totalOpStr = totalOpStr.trim();
          await printer.printLeftRight('Jml Operasional', totalOpStr, 1);
        } else {
          print('Tidak ada operasional ditemukan');
        }

        await printer.printCustom('========================', 1, 1);

        // TOTAL AKHIR (1 BARIS, KANAN)
        double totalAkhir = totalHrg;

        // Hitung ulang dengan operasional
        for (var op in operasionals) {
          final biaya = (op['biaya'] as num).toDouble();
          if (op['tipe'] == 'tambah') {
            totalAkhir += biaya;
          } else {
            totalAkhir -= biaya;
          }
        }

        String label = 'TOTAL AKHIR';
        String nilai = formatter.format(totalAkhir);

        // Gabungkan dengan padding agar ke kanan
        String nilaiFormatted = formatter.format(totalAkhir);
        String barisTotal = label.padRight(20) + nilaiFormatted.padLeft(12);
        await printer.printCustom(barisTotal, 1, 2);
        await printer.printNewLine();

        // FOOTER
        await printer.printCustom(footerText, 0, 1);

        await printer.printNewLine();
        await printer.printNewLine();
        await printer.printNewLine();

        // Potong kertas
        await printer.paperCut();

        // Tunggu sebelum mencetak duplikat (jika perlu)
        if (duplicatePrint) {
          await Future.delayed(Duration(seconds: 2));
          await _cetakStrukLangsung(); // Panggil ulang untuk duplikat
        }

        // Putuskan koneksi setelah selesai (opsional)
        await Future.delayed(Duration(milliseconds: 500));
        await printer.disconnect();

        // Feedback sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Struk berhasil dicetak'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset form setelah cetak
        resetForm();
      } catch (e) {
        // Pastikan dialog loading ditutup jika ada error
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print('Printing connection error: $e');
        rethrow; // Lanjutkan ke catch block luar
      }
    } catch (e) {
      print('Printing error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      // TIDAK reset form di sini agar data tidak hilang
    }
  }

  Future<bool> _testPrinterConnection() async {
    try {
      final printerName = _prefs.getPrinterNameSync();
      final printerAddress = _prefs.getPrinterAddressSync();

      if (printerName == null || printerAddress == null) {
        return false;
      }

      final printer = BlueThermalPrinter.instance;
      List<BluetoothDevice> devices = await printer.getBondedDevices();

      for (var device in devices) {
        if (device.name == printerName && device.address == printerAddress) {
          // Coba koneksi
          bool? isConnected = await printer.isConnected;

          if (isConnected == true) {
            await printer.disconnect();
            await Future.delayed(Duration(milliseconds: 500));
          }

          await printer.connect(device);
          await Future.delayed(Duration(milliseconds: 1500));

          isConnected = await printer.isConnected;
          return isConnected == true;
        }
      }

      return false;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  // Fungsi untuk cek dan request permission Bluetooth
  Future<bool> _checkBluetoothPermissions() async {
    try {
      // Cek dan request permission untuk Android 12+
      if (await Permission.bluetoothConnect.request().isGranted &&
          await Permission.bluetoothScan.request().isGranted &&
          await Permission.locationWhenInUse.request().isGranted) {
        return true;
      }

      // Fallback untuk Android versi lama
      if (await Permission.bluetooth.request().isGranted &&
          await Permission.location.request().isGranted) {
        return true;
      }

      // Jika permission ditolak, tampilkan dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Permission Bluetooth Diperlukan'),
          content: Text(
            'Aplikasi memerlukan izin Bluetooth dan Lokasi untuk menghubungkan ke printer. '
            'Silakan berikan izin di pengaturan perangkat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: Text('Buka Pengaturan'),
            ),
          ],
        ),
      );

      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  // Di fungsi _saveCurrentTransaction(), tambahkan:
  Future<void> _saveCurrentTransaction() async {
    try {
      Map<String, dynamic> transactionData = {
        'noFaktur': noFaktur,
        'pembeli': pembeli,
        'alamat': alamat,
        'kayu': kayu,
        'selectedPembeliId': selectedPembeliId,
        'selectedPembeliNama': selectedPembeliNama,
        'selectedPembeliAlamat': selectedPembeliAlamat,
        'selectedKayuId': selectedKayuId,
        'selectedKayuNama': selectedKayuNama,
        'data': data,
        'operasionals': operasionals,
        'customVolumes': customVolumes,
        'harga': harga,
        'modalVisible': modalVisible,
        'selectedCustomKriteria': selectedCustomKriteria,
        'diameter': diameter,
        'panjang': panjang,
        'customDiameter': customDiameter,
        'customVolumeValue': customVolumeValue,
        'operasionalTipe': operasionalTipe,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'current_penjualan_transaction',
        json.encode(transactionData),
      );

      print('=== TRANSACTION SAVED ===');
      print('Data items: ${data.length}');
      print('Operasionals: ${operasionals.length}');
      for (var op in operasionals) {
        print('- ${op['jenis']}: ${op['biaya']} (${op['tipe']})');
      }
      print('=====================');
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Di dalam class _TransaksiPenjualanState, modifikasi fungsi _loadDataDariDatabase:

// Fungsi untuk memuat data kayu dari SQLite berdasarkan pembeli yang dipilih
Future<void> _loadHargaJualByPembeli(String? pembeliId) async {
  try {
    if (pembeliId == null || pembeliId.isEmpty) {
      setState(() {
        daftarKayu = [];
      });
      return;
    }

    final db = await _dbService.database;
    
    // Query untuk mendapatkan harga jual berdasarkan pembeli_id
    final kayuData = await db.rawQuery('''
      SELECT 
        hj.id,
        hj.nama_kayu,
        hj.harga_rijek_1,
        hj.harga_rijek_2,
        hj.harga_standar,
        hj.harga_super_a,
        hj.harga_super_b,
        hj.harga_super_c
      FROM harga_jual hj
      WHERE hj.pembeli_id = ?
      ORDER BY hj.nama_kayu ASC
    ''', [int.parse(pembeliId)]);

    setState(() {
      daftarKayu = kayuData
          .map(
            (item) => {
              'id': item['id'].toString(),
              'nama_kayu': item['nama_kayu'] ?? '',
              'harga_rijek_1': item['harga_rijek_1'] ?? 0,
              'harga_rijek_2': item['harga_rijek_2'] ?? 0,
              'harga_standar': item['harga_standar'] ?? 0,
              'harga_super_a': item['harga_super_a'] ?? 0,
              'harga_super_b': item['harga_super_b'] ?? 0,
              'harga_super_c': item['harga_super_c'] ?? 0,
            },
          )
          .toList();
      
      // Reset selected kayu jika tidak ada dalam daftar baru
      if (selectedKayuId != null) {
        bool kayuExists = daftarKayu.any((k) => k['id'] == selectedKayuId);
        if (!kayuExists) {
          selectedKayuId = null;
          selectedKayuNama = null;
          kayu = '';
          harga = {
            'Rijek 1': 0.0,
            'Rijek 2': 0.0,
            'Standar': 0.0,
            'Super A': 0.0,
            'Super B': 0.0,
            'Super C': 0.0,
          };
        }
      }
    });
  } catch (error) {
    print('Error loading harga jual by pembeli: $error');
  }
}

// Modifikasi onChanged di dropdown pembeli:
onChanged: (String? value) {
  setState(() {
    selectedPembeliId = value;
    final selected = daftarPembeli.firstWhere(
      (p) => p['id']?.toString() == value,
      orElse: () => <String, dynamic>{},
    );
    if (selected.isNotEmpty) {
      selectedPembeliNama = selected['nama']?.toString();
      selectedPembeliAlamat = selected['alamat']?.toString();
      pembeli = selectedPembeliNama ?? '';
      alamat = selectedPembeliAlamat ?? '';
      
      // Load harga jual berdasarkan pembeli yang dipilih
      _loadHargaJualByPembeli(value);
    } else {
      // Reset jika pembeli tidak ditemukan
      selectedPembeliNama = null;
      selectedPembeliAlamat = null;
      pembeli = '';
      alamat = '';
      daftarKayu = [];
      selectedKayuId = null;
      selectedKayuNama = null;
      kayu = '';
      harga = {
        'Rijek 1': 0.0,
        'Rijek 2': 0.0,
        'Standar': 0.0,
        'Super A': 0.0,
        'Super B': 0.0,
        'Super C': 0.0,
      };
    }
  });
},

// Modifikasi onChanged di dropdown kayu tetap sama:
onChanged: (String? value) {
  setState(() {
    selectedKayuId = value;
    final selected = daftarKayu.firstWhere(
      (k) => k['id']?.toString() == value,
      orElse: () => <String, dynamic>{},
    );

    if (selected.isNotEmpty) {
      selectedKayuNama = selected['nama_kayu']?.toString();
      kayu = selectedKayuNama ?? '';

      // Set harga dari data SQLite
      harga = {
        'Rijek 1': selected['harga_rijek_1'] ?? 0,
        'Rijek 2': selected['harga_rijek_2'] ?? 0,
        'Standar': selected['harga_standar'] ?? 0,
        'Super A': selected['harga_super_a'] ?? 0,
        'Super B': selected['harga_super_b'] ?? 0,
        'Super C': selected['harga_super_c'] ?? 0,
      };
    } else {
      selectedKayuNama = null;
      kayu = '';
      harga = {
        'Rijek 1': 0.0,
        'Rijek 2': 0.0,
        'Standar': 0.0,
        'Super A': 0.0,
        'Super B': 0.0,
        'Super C': 0.0,
      };
    }
  });
},

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi Penjualan'),
        actions: [
          // Tombol untuk ke halaman pengaturan
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              // Simpan transaksi yang sedang berlangsung sebelum pindah
              if (data.isNotEmpty) {
                await _saveCurrentTransaction();
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PengaturanPage()),
              ).then((_) {
                // Saat kembali dari pengaturan, muat ulang data
                _loadSavedTransaction();
              });
            },
            tooltip: 'Pengaturan Printer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            // Header dengan tombol Input Data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      modalVisible = true;
                    });
                  },
                  child: Text('Input Data'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('No Faktur: $noFaktur'),
                    Text('Pembeli: ${pembeli.isNotEmpty ? pembeli : "-"}'),
                    Text('Kayu: ${kayu.isNotEmpty ? kayu : "-"}'),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // Custom Kriteria
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Custom :',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          {'short': 'St', 'full': 'Standar'},
                          {'short': 'Sp A', 'full': 'Super A'},
                          {'short': 'Sp B', 'full': 'Super B'},
                          {'short': 'Sp C', 'full': 'Super C'},
                        ].map((item) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCustomKriteria =
                                    selectedCustomKriteria == item['full']
                                    ? null
                                    : item['full'];
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selectedCustomKriteria == item['full']
                                    ? Colors.lightBlue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item['short'].toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedCustomKriteria == item['full']
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Input Panjang dan Diameter
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panjang:'),
                      TextField(
                        controller: panjangController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Panjang',
                        ),
                        onChanged: (value) => setState(() => panjang = value),
                        onTap: () {
                          panjangController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: panjangController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diameter:'),
                      TextField(
                        controller: diameterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Diameter',
                        ),
                        onChanged: (value) => setState(() => diameter = value),
                        onTap: () {
                          diameterController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: diameterController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: handleAddOrUpdate,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Tabel Data Transaksi
            Text(
              'Data Transaksi Penjualan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Header Tabel
            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(2),
                7: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Grd',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'D',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'P',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Jml',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Vol',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Hrg',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Aksi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Isi Tabel dengan Scroll
            SizedBox(
              height: 250,
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    var item = data[index];
                    return Container(
                      color: item['id'] == latestItemId
                          ? Color(0xFFd0f0c0)
                          : Colors.white,
                      child: Table(
                        border: TableBorder.all(),
                        columnWidths: {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1),
                          6: FlexColumnWidth(2),
                          7: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            children: [
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      getShortLabel(item['kriteria']),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      item['diameter'].toInt().toString(),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      item['panjang'].toInt().toString(),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      item['jumlah'].toInt().toString(),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(
                                      item['volume'].toInt().toString(),
                                    ),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['harga'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Text(item['jumlahHarga'].toString()),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(24, 24),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () =>
                                          handleDecrement(item['id']),
                                      child: Icon(Icons.remove, size: 18),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(24, 24),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () =>
                                          updateJumlah(item['id'], 1),
                                      child: Icon(Icons.add, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),

            // Custom Volume
            Text(
              'Custom Volume (Opsional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diameter:'),
                      TextField(
                        controller: customDiameterController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Diameter',
                        ),
                        onChanged: (value) =>
                            setState(() => customDiameter = value),
                        onTap: () {
                          customDiameterController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: customDiameterController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volume:'),
                      TextField(
                        controller: customVolumeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Volume',
                        ),
                        onChanged: (value) =>
                            setState(() => customVolumeValue = value),
                        onTap: () {
                          customVolumeController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: customVolumeController.text.length,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                double d = double.tryParse(customDiameter) ?? 0;
                int v = int.tryParse(customVolumeValue) ?? 0;
                if (d > 0 && v > 0) {
                  setState(() {
                    customVolumes.removeWhere((c) => c['diameter'] == d);
                    customVolumes.add({'diameter': d, 'volume': v});
                    customDiameter = '';
                    customVolumeValue = '';
                  });
                }
              },
              child: Text('Tambah Custom Volume'),
            ),
            SizedBox(height: 10),
            if (customVolumes.isNotEmpty) ...[
              Text('Daftar Custom Volume:'),
              ...customVolumes.map((c) {
                return Row(
                  children: [
                    Text('Diameter ${c['diameter']}: Volume ${c['volume']}'),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          customVolumes.removeWhere(
                            (item) => item['diameter'] == c['diameter'],
                          );
                        });
                      },
                    ),
                  ],
                );
              }),
            ],

            // Tombol Aksi
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleSimpanTransaksi(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(200, 50),
                  ),
                  child: Text('SIMPAN & CETAK', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),

      // Modal Input Data Penjualan
      floatingActionButton: modalVisible
          ? Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Data Penjualan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('No Faktur: $noFaktur'),
                    SizedBox(height: 10),

                    // Dropdown untuk memilih Pembeli
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Pilih Pembeli',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPembeliId,
                      items: daftarPembeli.map<DropdownMenuItem<String>>((
                        pembeli,
                      ) {
                        final idStr = pembeli['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: idStr,
                          child: Text(pembeli['nama']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedPembeliId = value;
                          final selected = daftarPembeli.firstWhere(
                            (p) => p['id']?.toString() == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selected.isNotEmpty) {
                            selectedPembeliNama = selected['nama']?.toString();
                            selectedPembeliAlamat = selected['alamat']
                                ?.toString();
                            pembeli = selectedPembeliNama ?? '';
                            alamat = selectedPembeliAlamat ?? '';
                          }
                        });
                      },
                    ),

                    SizedBox(height: 10),
                    Text('Alamat: ${selectedPembeliAlamat ?? ''}'),
                    SizedBox(height: 10),

                    // Dropdown untuk memilih Kayu
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Pilih Jenis Kayu',
                        border: OutlineInputBorder(),
                      ),
                      value:
                          daftarKayu.any(
                            (k) => k['id'].toString() == selectedKayuId,
                          )
                          ? selectedKayuId
                          : null,
                      items: daftarKayu.map<DropdownMenuItem<String>>((kayu) {
                        final idStr = kayu['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: idStr,
                          child: Text(kayu['nama_kayu']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedKayuId = value;
                          final selected = daftarKayu.firstWhere(
                            (k) => k['id']?.toString() == value,
                            orElse: () => <String, dynamic>{},
                          );

                          if (selected.isNotEmpty) {
                            selectedKayuNama = selected['nama_kayu']
                                ?.toString();
                            kayu = selectedKayuNama ?? '';

                            // Set harga dari data SQLite
                            harga = {
                              'Rijek 1': selected['harga_rijek_1'] ?? 0,
                              'Rijek 2': selected['harga_rijek_2'] ?? 0,
                              'Standar': selected['harga_standar'] ?? 0,
                              'Super A': selected['harga_super_a'] ?? 0,
                              'Super B': selected['harga_super_b'] ?? 0,
                              'Super C': selected['harga_super_c'] ?? 0,
                            };
                          }
                        });
                      },
                    ),

                    // Operasional
                    SizedBox(height: 20),
                    Text(
                      'Biaya Operasional:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),

                    ...operasionals.map((op) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 5),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Jenis: ${op['jenis']}'),
                                    Text(
                                      'Biaya: ${formatter.format(op['biaya'])}',
                                    ),
                                    Text(
                                      'Tipe: ${op['tipe'] == 'tambah' ? 'Menambah' : 'Mengurangi'}',
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    operasionals.removeWhere(
                                      (item) => item['id'] == op['id'],
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    // Form untuk menambah operasional baru
                    SizedBox(height: 10),
                    TextField(
                      controller: operasionalJenisController,
                      decoration: InputDecoration(
                        labelText: 'Jenis Operasional',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: operasionalBiayaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Biaya (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Tipe:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text(
                                  'Menambah',
                                  style: TextStyle(fontSize: 12),
                                ),
                                selected: operasionalTipe == 'tambah',
                                onSelected: (selected) {
                                  setState(() {
                                    operasionalTipe = selected
                                        ? 'tambah'
                                        : 'kurang';
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text(
                                  'Mengurangi',
                                  style: TextStyle(fontSize: 12),
                                ),
                                selected: operasionalTipe == 'kurang',
                                onSelected: (selected) {
                                  setState(() {
                                    operasionalTipe = selected
                                        ? 'kurang'
                                        : 'tambah';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final jenis = operasionalJenisController.text.trim();
                        final biaya =
                            int.tryParse(operasionalBiayaController.text) ?? 0;

                        if (jenis.isNotEmpty && biaya > 0) {
                          setState(() {
                            operasionals.add({
                              'id': DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              'jenis': jenis,
                              'biaya': biaya,
                              'tipe': operasionalTipe,
                            });
                            operasionalJenisController.clear();
                            operasionalBiayaController.clear();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Isi jenis dan biaya dengan benar'),
                            ),
                          );
                        }
                      },
                      child: Text('+ Tambah Operasional'),
                    ),

                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedPembeliId != null &&
                                  selectedKayuId != null) {
                                setState(() {
                                  modalVisible = false;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pilih pembeli dan jenis kayu terlebih dahulu',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text('Simpan'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                modalVisible = false;
                              });
                            },
                            child: Text('Batal'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
