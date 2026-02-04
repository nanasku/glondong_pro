import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tpk_app/pages/pengaturan_page.dart';
import 'package:tpk_app/services/database_service.dart';
import 'package:tpk_app/services/preferences_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransaksiInputData extends StatefulWidget {
  // Parameter untuk menerima data dari nota fisik
  final Map<String, dynamic>? dataNota;

  const TransaksiInputData({super.key, this.dataNota});

  @override
  _TransaksiInputDataState createState() => _TransaksiInputDataState();
}

// ENUM untuk jenis harga - DIPINDAHKAN KE LUAR CLASS
enum HargaType { umum, level1, level2, level3 }

class _TransaksiInputDataState extends State<TransaksiInputData>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Ini akan menjaga state saat pindah halaman

  String? selectedCustomKriteria;
  bool modalVisible = false;
  String noFaktur = '';
  String penjual = '';
  String alamat = '';
  String kayu = '';

  // Variabel untuk jenis harga
  HargaType selectedHargaType = HargaType.umum;

  Map<String, dynamic> harga = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  Map<String, dynamic> hargaLevel1 = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  Map<String, dynamic> hargaLevel2 = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  Map<String, dynamic> hargaLevel3 = {
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
  String jumlahBatang = ''; // Field baru untuk jumlah batang, default 1
  List<Map<String, dynamic>> data = [];
  String? latestItemId;

  List<Map<String, dynamic>> customVolumes = [];
  String customDiameter = '';
  String customVolumeValue = '';

  ScrollController _scrollController = ScrollController();
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefs = PreferencesService();

  // Data dari database SQLite
  List<Map<String, dynamic>> daftarPenjual = [];
  List<Map<String, dynamic>> daftarKayu = [];
  String? selectedPenjualId;
  String? selectedKayuId;
  String? selectedPenjualNama;
  String? selectedPenjualAlamat;
  String? selectedKayuNama;

  // Variabel untuk operasional
  List<Map<String, dynamic>> operasionals = [];
  TextEditingController operasionalJenisController = TextEditingController();
  TextEditingController operasionalBiayaController = TextEditingController();
  String operasionalTipe = 'tambah';

  // TextEditingController
  TextEditingController diameterController = TextEditingController();
  TextEditingController panjangController = TextEditingController();
  TextEditingController jumlahBatangController = TextEditingController(
    text: '',
  ); // Controller baru
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
    _loadSavedTransaction();

    // Load data dari nota fisik jika ada
    if (widget.dataNota != null) {
      _loadDataFromNota(widget.dataNota!);
    }
  }

  // Fungsi untuk memuat data dari nota fisik
  void _loadDataFromNota(Map<String, dynamic> dataNota) {
    setState(() {
      // Set data dari nota fisik
      selectedPenjualId = dataNota['penjual_id']?.toString();
      selectedPenjualNama = dataNota['penjual_nama']?.toString();
      selectedPenjualAlamat = dataNota['penjual_alamat']?.toString();
      penjual = selectedPenjualNama ?? '';
      alamat = selectedPenjualAlamat ?? '';

      selectedKayuId = dataNota['kayu_id']?.toString();
      selectedKayuNama = dataNota['kayu_nama']?.toString();
      kayu = selectedKayuNama ?? '';

      // Load harga dari database berdasarkan kayu
      if (selectedKayuId != null) {
        _loadHargaKayu(selectedKayuId!);
      }
    });
  }

  Future<void> _initializeDatabase() async {
    await _dbService.initializeDatabase();
    getNoFakturBaru();
    _loadDataDariDatabase();
  }

  @override
  void dispose() {
    if (data.isNotEmpty) {
      _saveCurrentTransaction();
    }

    diameterController.dispose();
    panjangController.dispose();
    jumlahBatangController.dispose(); // Dispose controller baru
    customDiameterController.dispose();
    customVolumeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      panjangController.clear();
      diameterController.clear();
      jumlahBatangController.clear();
      jumlahBatangController.clear(); // Reset ke default
      customDiameterController.clear();
      customVolumeController.clear();
      operasionalJenisController.clear();
      operasionalBiayaController.clear();

      selectedCustomKriteria = null;
      selectedPenjualId = null;
      selectedPenjualNama = null;
      selectedPenjualAlamat = null;
      selectedKayuId = null;
      selectedKayuNama = null;
      selectedHargaType = HargaType.umum;

      penjual = '';
      alamat = '';
      kayu = '';
      diameter = '';
      panjang = '';
      jumlahBatang = ''; // Reset ke default
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

      hargaLevel1 = {
        'Rijek 1': 0.0,
        'Rijek 2': 0.0,
        'Standar': 0.0,
        'Super A': 0.0,
        'Super B': 0.0,
        'Super C': 0.0,
      };

      hargaLevel2 = {
        'Rijek 1': 0.0,
        'Rijek 2': 0.0,
        'Standar': 0.0,
        'Super A': 0.0,
        'Super B': 0.0,
        'Super C': 0.0,
      };

      hargaLevel3 = {
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
    _clearSavedTransaction();
  }

  double get totalVolume {
    return data.fold(0, (sum, item) => sum + (item['volume'] * item['jumlah']));
  }

  double get totalHarga {
    return data.fold(0, (sum, item) => sum + item['jumlahHarga']);
  }

  Future<void> _loadDataDariDatabase() async {
    await _loadPenjual();
    await _loadKayu();
  }

  // Fungsi untuk memuat harga kayu berdasarkan ID
  Future<void> _loadHargaKayu(String kayuId) async {
    try {
      // Load semua data kayu terlebih dahulu jika belum dimuat
      if (daftarKayu.isEmpty) {
        await _loadKayu();
      }

      // Cari kayu dari daftarKayu
      final selectedKayuList = daftarKayu
          .where((k) => k['id']?.toString() == kayuId)
          .toList();

      if (selectedKayuList.isNotEmpty) {
        final item = selectedKayuList.first;
        setState(() {
          harga = {
            'Rijek 1': (item['harga_rijek_1'] ?? 0).toDouble(),
            'Rijek 2': (item['harga_rijek_2'] ?? 0).toDouble(),
            'Standar': (item['harga_standar'] ?? 0).toDouble(),
            'Super A': (item['harga_super_a'] ?? 0).toDouble(),
            'Super B': (item['harga_super_b'] ?? 0).toDouble(),
            'Super C': (item['harga_super_c'] ?? 0).toDouble(),
          };

          hargaLevel1 = {
            'Rijek 1': (item['harga_rijek_1_level1'] ?? 0).toDouble(),
            'Rijek 2': (item['harga_rijek_2_level1'] ?? 0).toDouble(),
            'Standar': (item['harga_standar_level1'] ?? 0).toDouble(),
            'Super A': (item['harga_super_a_level1'] ?? 0).toDouble(),
            'Super B': (item['harga_super_b_level1'] ?? 0).toDouble(),
            'Super C': (item['harga_super_c_level1'] ?? 0).toDouble(),
          };

          hargaLevel2 = {
            'Rijek 1': (item['harga_rijek_1_level2'] ?? 0).toDouble(),
            'Rijek 2': (item['harga_rijek_2_level2'] ?? 0).toDouble(),
            'Standar': (item['harga_standar_level2'] ?? 0).toDouble(),
            'Super A': (item['harga_super_a_level2'] ?? 0).toDouble(),
            'Super B': (item['harga_super_b_level2'] ?? 0).toDouble(),
            'Super C': (item['harga_super_c_level2'] ?? 0).toDouble(),
          };

          hargaLevel3 = {
            'Rijek 1': (item['harga_rijek_1_level3'] ?? 0).toDouble(),
            'Rijek 2': (item['harga_rijek_2_level3'] ?? 0).toDouble(),
            'Standar': (item['harga_standar_level3'] ?? 0).toDouble(),
            'Super A': (item['harga_super_a_level3'] ?? 0).toDouble(),
            'Super B': (item['harga_super_b_level3'] ?? 0).toDouble(),
            'Super C': (item['harga_super_c_level3'] ?? 0).toDouble(),
          };
        });
      }
    } catch (error) {
      print('Error loading harga kayu: $error');
    }
  }

  Future<void> _loadPenjual() async {
    try {
      final penjualData = await _dbService.getAllPenjual();
      setState(() {
        daftarPenjual = penjualData
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
      print('Error loading penjual: $error');
    }
  }

  Future<void> _loadKayu() async {
    try {
      final kayuData = await _dbService.getAllHargaBeli();
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

                'harga_rijek_1_level1': item['harga_rijek_1_level1'] ?? 0,
                'harga_rijek_2_level1': item['harga_rijek_2_level1'] ?? 0,
                'harga_standar_level1': item['harga_standar_level1'] ?? 0,
                'harga_super_a_level1': item['harga_super_a_level1'] ?? 0,
                'harga_super_b_level1': item['harga_super_b_level1'] ?? 0,
                'harga_super_c_level1': item['harga_super_c_level1'] ?? 0,

                'harga_rijek_1_level2': item['harga_rijek_1_level2'] ?? 0,
                'harga_rijek_2_level2': item['harga_rijek_2_level2'] ?? 0,
                'harga_standar_level2': item['harga_standar_level2'] ?? 0,
                'harga_super_a_level2': item['harga_super_a_level2'] ?? 0,
                'harga_super_b_level2': item['harga_super_b_level2'] ?? 0,
                'harga_super_c_level2': item['harga_super_c_level2'] ?? 0,

                'harga_rijek_1_level3': item['harga_rijek_1_level3'] ?? 0,
                'harga_rijek_2_level3': item['harga_rijek_2_level3'] ?? 0,
                'harga_standar_level3': item['harga_standar_level3'] ?? 0,
                'harga_super_a_level3': item['harga_super_a_level3'] ?? 0,
                'harga_super_b_level3': item['harga_super_b_level3'] ?? 0,
                'harga_super_c_level3': item['harga_super_c_level3'] ?? 0,
              },
            )
            .toList();
      });
    } catch (error) {
      print('Error loading kayu: $error');
    }
  }

  Future<void> getNoFakturBaru() async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('ddMMyy').format(now);

      final db = await _dbService.database;
      final lastFaktur = await db.query(
        'pembelian',
        where: 'faktur_pemb LIKE ?',
        whereArgs: ['PB$dateStr%'],
        orderBy: 'id DESC',
        limit: 1,
      );

      int nextNumber = 1;
      if (lastFaktur.isNotEmpty) {
        final lastFakturStr = lastFaktur.first['faktur_pemb'] as String;
        final lastNum = int.tryParse(lastFakturStr.substring(8)) ?? 0;
        nextNumber = lastNum + 1;
      }

      setState(() {
        noFaktur = 'PB${dateStr}${nextNumber.toString().padLeft(3, '0')}';
      });
    } catch (e) {
      setState(() {
        noFaktur = 'PB${DateFormat('ddMMyy').format(DateTime.now())}001';
      });
    }
  }

  double _getHargaBerdasarkanType(String kriteria) {
    switch (selectedHargaType) {
      case HargaType.level1:
        return (hargaLevel1[kriteria] ?? 0).toDouble();
      case HargaType.level2:
        return (hargaLevel2[kriteria] ?? 0).toDouble();
      case HargaType.level3:
        return (hargaLevel3[kriteria] ?? 0).toDouble();
      case HargaType.umum:
      default:
        return (harga[kriteria] ?? 0).toDouble();
    }
  }

  String _getHargaTypeLabel() {
    switch (selectedHargaType) {
      case HargaType.umum:
        return 'Um';
      case HargaType.level1:
        return 'Lv 1';
      case HargaType.level2:
        return 'Lv 2';
      case HargaType.level3:
        return 'Lv 3';
      default:
        return 'Um';
    }
  }

  void handleAddOrUpdate() {
    if (diameter.isEmpty || panjang.isEmpty) return;

    double d = double.tryParse(diameter) ?? 0;
    double p = double.tryParse(panjang) ?? 0;
    int jml = int.tryParse(jumlahBatang) ?? 1; // Tetap default 1 jika kosong
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
    double hargaSatuan = _getHargaBerdasarkanType(
      currentKriteria,
    ).round().toDouble();

    if (hargaSatuan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Harga tidak ditemukan untuk grade $currentKriteria (${_getHargaTypeLabel()})',
          ),
        ),
      );
      return;
    }

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

    int jumlahHarga = (volume * hargaSatuan * jml)
        .round(); // Hitung dengan jumlah batang

    int existingIndex = data.indexWhere(
      (item) =>
          item['diameter'] == d &&
          item['panjang'] == p &&
          item['kriteria'] == currentKriteria &&
          item['hargaType'] == selectedHargaType.toString(),
    );

    List<Map<String, dynamic>> updatedData;
    if (existingIndex >= 0) {
      updatedData = List<Map<String, dynamic>>.from(data);
      var item = updatedData[existingIndex];
      int newJumlah = item['jumlah'] + jml; // Tambah dengan jumlah batang
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
        'jumlah': jml, // Gunakan jumlah batang
        'volume': volume,
        'harga': hargaSatuan,
        'jumlahHarga': jumlahHarga,
        'hargaType': selectedHargaType.toString(),
        'hargaTypeLabel': _getHargaTypeLabel(),
      };
      updatedData = sortData([...data, newItem]);
      setState(() {
        latestItemId = newItem['id'].toString();
        data = updatedData;
      });
    }

    // Reset field input setelah ditambahkan - HANYA Diameter dan Jumlah Batang
    setState(() {
      diameter = '';
      jumlahBatang = ''; // Hanya di-clear, tanpa default
      diameterController.clear();
      jumlahBatangController.clear(); // Hanya clear, tanpa set ke '1'

      // Panjang TIDAK direset, tetap ada nilainya
    });

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

  Future<void> _loadSavedTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('current_inputdata_transaction');

      if (savedData != null && savedData.isNotEmpty) {
        final transactionData = json.decode(savedData) as Map<String, dynamic>;

        setState(() {
          noFaktur = transactionData['noFaktur'] ?? noFaktur;
          penjual = transactionData['penjual'] ?? '';
          alamat = transactionData['alamat'] ?? '';
          kayu = transactionData['kayu'] ?? '';
          selectedPenjualId = transactionData['selectedPenjualId'];
          selectedPenjualNama = transactionData['selectedPenjualNama'];
          selectedPenjualAlamat = transactionData['selectedPenjualAlamat'];
          selectedKayuId = transactionData['selectedKayuId'];
          selectedKayuNama = transactionData['selectedKayuNama'];

          final hargaTypeStr =
              transactionData['selectedHargaType'] ?? 'HargaType.umum';
          if (hargaTypeStr.contains('level1')) {
            selectedHargaType = HargaType.level1;
          } else if (hargaTypeStr.contains('level2')) {
            selectedHargaType = HargaType.level2;
          } else if (hargaTypeStr.contains('level3')) {
            selectedHargaType = HargaType.level3;
          } else {
            selectedHargaType = HargaType.umum;
          }

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
          hargaLevel1 = Map<String, dynamic>.from(
            transactionData['hargaLevel1'] ?? {},
          );
          hargaLevel2 = Map<String, dynamic>.from(
            transactionData['hargaLevel2'] ?? {},
          );
          hargaLevel3 = Map<String, dynamic>.from(
            transactionData['hargaLevel3'] ?? {},
          );

          modalVisible = transactionData['modalVisible'] ?? false;
          selectedCustomKriteria = transactionData['selectedCustomKriteria'];
          diameter = transactionData['diameter'] ?? '';
          panjang = transactionData['panjang'] ?? '';
          jumlahBatang =
              transactionData['jumlahBatang'] ?? ''; // Load jumlah batang
          customDiameter = transactionData['customDiameter'] ?? '';
          customVolumeValue = transactionData['customVolumeValue'] ?? '';
          operasionalTipe = transactionData['operasionalTipe'] ?? 'tambah';

          diameterController.text = diameter;
          panjangController.text = panjang;
          jumlahBatangController.text = jumlahBatang; // Set controller
          customDiameterController.text = customDiameter;
          customVolumeController.text = customVolumeValue;
        });
      }
    } catch (e) {
      print('Error loading saved transaction: $e');
    }
  }

  Future<void> _clearSavedTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_inputdata_transaction');
  }

  Future<void> _handleSimpanTransaksi() async {
    try {
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada data transaksi untuk disimpan')),
        );
        return;
      }

      if (selectedPenjualId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih penjual terlebih dahulu')),
        );
        return;
      }

      if (selectedKayuId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih jenis kayu terlebih dahulu')),
        );
        return;
      }

      bool saveSuccess = await _simpanKeDatabase();

      if (!saveSuccess) {
        return;
      }

      bool? confirmPrint = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cetak Struk'),
            content: Text('Apakah Anda ingin mencetak struk pembelian?'),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (data.isNotEmpty) {
        _saveCurrentTransaction();
      }
    });
  }

  Future<bool> _simpanKeDatabase() async {
    try {
      final db = await _dbService.database;

      double totalHarga = data.fold<double>(
        0.0,
        (sum, item) => sum + (item['jumlahHarga'] as num).toDouble(),
      );

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

      await db.transaction((txn) async {
        await txn.insert('pembelian', {
          'faktur_pemb': noFaktur,
          'penjual_id': int.tryParse(selectedPenjualId ?? '0'),
          'product_id': int.tryParse(selectedKayuId ?? '0'),
          'total': totalAkhir.round(),
          'created_at': DateTime.now().toIso8601String(),
        });

        for (var item in data) {
          await txn.insert('pembelian_detail', {
            'faktur_pemb': noFaktur,
            'nama_kayu': kayu,
            'kriteria': item['kriteria'],
            'diameter': item['diameter'],
            'panjang': item['panjang'],
            'jumlah': item['jumlah'],
            'volume': item['volume'],
            'harga_beli': item['harga'],
            'jumlah_harga_beli': item['jumlahHarga'],
            'harga_type': item['hargaTypeLabel'],
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        for (var op in operasionals) {
          await txn.insert('pembelian_operasional', {
            'faktur_pemb': noFaktur,
            'jenis': op['jenis'],
            'biaya': op['biaya'],
            'tipe': op['tipe'],
          });
        }

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

      return true;
    } catch (error) {
      print('Error menyimpan transaksi: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan transaksi')));

      return false;
    }
  }

  Future<void> _saveCurrentTransaction() async {
    try {
      Map<String, dynamic> transactionData = {
        'noFaktur': noFaktur,
        'penjual': penjual,
        'alamat': alamat,
        'kayu': kayu,
        'selectedPenjualId': selectedPenjualId,
        'selectedPenjualNama': selectedPenjualNama,
        'selectedPenjualAlamat': selectedPenjualAlamat,
        'selectedKayuId': selectedKayuId,
        'selectedKayuNama': selectedKayuNama,
        'selectedHargaType': selectedHargaType.toString(),
        'data': data,
        'operasionals': operasionals,
        'customVolumes': customVolumes,
        'harga': harga,
        'hargaLevel1': hargaLevel1,
        'hargaLevel2': hargaLevel2,
        'hargaLevel3': hargaLevel3,
        'modalVisible': modalVisible,
        'selectedCustomKriteria': selectedCustomKriteria,
        'diameter': diameter,
        'panjang': panjang,
        'jumlahBatang': jumlahBatang, // Simpan jumlah batang
        'customDiameter': customDiameter,
        'customVolumeValue': customVolumeValue,
        'operasionalTipe': operasionalTipe,
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'current_inputdata_transaction',
        json.encode(transactionData),
      );
    } catch (e) {
      print('Error saving transaction: $e');
    }
  }

  // Tambahkan fungsi _cetakStrukLangsung yang hilang
  Future<void> _cetakStrukLangsung() async {
    try {
      final printerName = _prefs.getPrinterNameSync();
      final printerAddress = _prefs.getPrinterAddressSync();
      final footerText = await _prefs.getFooterText() ?? 'TERIMA KASIH';
      final namaPerusahaan = await _prefs.getNamaPerusahaan() ?? '';
      final alamatPerusahaan = await _prefs.getAlamatPerusahaan() ?? '';
      final teleponPerusahaan = await _prefs.getTeleponPerusahaan() ?? '';
      final autoPrint = await _prefs.getAutoPrint() ?? false;
      final duplicatePrint = await _prefs.getDuplicatePrint() ?? false;

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

      final printer = BlueThermalPrinter.instance;

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
        bool? isConnected = await printer.isConnected;

        if (isConnected == true) {
          await printer.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
        }

        await printer.connect(targetDevice);
        await Future.delayed(Duration(milliseconds: 1500));

        isConnected = await printer.isConnected;

        if (isConnected != true) {
          Navigator.pop(context);
          throw Exception(
            'Gagal terhubung ke printer. Pastikan printer dalam keadaan ON dan sudah dipasangkan (paired).',
          );
        }

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sedang mencetak struk...'),
            backgroundColor: Colors.blue,
          ),
        );

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

        String penjualLine =
            'Penjual'.padRight(lineWidth - penjual.length) + penjual;
        await printer.printCustom(penjualLine, 1, 0);

        String kayuLine = 'Kayu'.padRight(lineWidth - kayu.length) + kayu;
        await printer.printCustom(kayuLine, 1, 0);

        String jenisHargaLine =
            'Jenis Harga'.padRight(lineWidth - _getHargaTypeLabel().length) +
            _getHargaTypeLabel();
        await printer.printCustom(jenisHargaLine, 1, 0);

        await printer.printCustom('------------------------', 1, 1);

        // DETAIL ITEM - FIXED: Type conversion
        for (var item in data) {
          String kriteria = getShortLabel(item['kriteria']);

          // Convert diameter to int safely
          int diameter = 0;
          if (item['diameter'] is double) {
            diameter = (item['diameter'] as double).round();
          } else if (item['diameter'] is int) {
            diameter = item['diameter'] as int;
          } else {
            diameter = int.tryParse(item['diameter'].toString()) ?? 0;
          }

          // Convert panjang to int safely
          int panjang = 0;
          if (item['panjang'] is double) {
            panjang = (item['panjang'] as double).round();
          } else if (item['panjang'] is int) {
            panjang = item['panjang'] as int;
          } else {
            panjang = int.tryParse(item['panjang'].toString()) ?? 0;
          }

          // Convert jumlah to int safely
          int jumlah = 0;
          if (item['jumlah'] is double) {
            jumlah = (item['jumlah'] as double).round();
          } else if (item['jumlah'] is int) {
            jumlah = item['jumlah'] as int;
          } else {
            jumlah = int.tryParse(item['jumlah'].toString()) ?? 0;
          }

          // Convert volume to int safely
          double volumeDouble = 0.0;
          if (item['volume'] is double) {
            volumeDouble = item['volume'] as double;
          } else if (item['volume'] is int) {
            volumeDouble = (item['volume'] as int).toDouble();
          } else {
            volumeDouble = double.tryParse(item['volume'].toString()) ?? 0.0;
          }
          int volume = volumeDouble.round();

          int totalVolume = (volume * jumlah);

          // Convert harga to int safely
          double hargaDouble = 0.0;
          if (item['harga'] is double) {
            hargaDouble = item['harga'] as double;
          } else if (item['harga'] is int) {
            hargaDouble = (item['harga'] as int).toDouble();
          } else {
            hargaDouble = double.tryParse(item['harga'].toString()) ?? 0.0;
          }
          int harga = hargaDouble.round();

          // Convert jumlahHarga to int safely
          double jumlahHargaDouble = 0.0;
          if (item['jumlahHarga'] is double) {
            jumlahHargaDouble = item['jumlahHarga'] as double;
          } else if (item['jumlahHarga'] is int) {
            jumlahHargaDouble = (item['jumlahHarga'] as int).toDouble();
          } else {
            jumlahHargaDouble =
                double.tryParse(item['jumlahHarga'].toString()) ?? 0.0;
          }
          int jumlahHarga = jumlahHargaDouble.round();

          String kiriHeader = '$kriteria D$diameter P$panjang';
          String kananHeader = '$jumlah x $volume cm3';
          await printer.printLeftRight(kiriHeader, kananHeader, 1);

          String detail =
              '$totalVolume cm3 x ${formatter.format(harga)} = ${formatter.format(jumlahHarga)}';
          await printer.printCustom(detail, 1, 2);
          await printer.printNewLine();
        }

        await printer.printCustom('------------------------', 1, 1);

        // TOTAL VOLUME & HARGA - FIXED: Type conversion
        double totalVol = data.fold(0.0, (sum, item) {
          double volume = 0.0;
          if (item['volume'] is double) {
            volume = item['volume'] as double;
          } else if (item['volume'] is int) {
            volume = (item['volume'] as int).toDouble();
          } else {
            volume = double.tryParse(item['volume'].toString()) ?? 0.0;
          }

          double jumlah = 0.0;
          if (item['jumlah'] is double) {
            jumlah = item['jumlah'] as double;
          } else if (item['jumlah'] is int) {
            jumlah = (item['jumlah'] as int).toDouble();
          } else {
            jumlah = double.tryParse(item['jumlah'].toString()) ?? 0.0;
          }

          return sum + (volume * jumlah);
        });
        await printer.printLeftRight(
          'Total Volume',
          '${totalVol.round()} cm3',
          1,
        );

        double totalHrg = data.fold(0.0, (sum, item) {
          double jumlahHarga = 0.0;
          if (item['jumlahHarga'] is double) {
            jumlahHarga = item['jumlahHarga'] as double;
          } else if (item['jumlahHarga'] is int) {
            jumlahHarga = (item['jumlahHarga'] as int).toDouble();
          } else {
            jumlahHarga =
                double.tryParse(item['jumlahHarga'].toString()) ?? 0.0;
          }
          return sum + jumlahHarga;
        });
        await printer.printLeftRight(
          'Total Harga',
          formatter.format(totalHrg.round()),
          1,
        );

        // BIAYA OPERASIONAL
        if (operasionals.isNotEmpty) {
          await printer.printCustom('------------------------', 1, 1);
          await printer.printCustom('BIAYA OPERASIONAL:', 1, 0);

          for (var op in operasionals) {
            String jenis = op['jenis'].toString();

            // Convert biaya to int safely
            double biayaDouble = 0.0;
            if (op['biaya'] is double) {
              biayaDouble = op['biaya'] as double;
            } else if (op['biaya'] is int) {
              biayaDouble = (op['biaya'] as int).toDouble();
            } else {
              biayaDouble = double.tryParse(op['biaya'].toString()) ?? 0.0;
            }
            int biaya = biayaDouble.round();

            String tipe = op['tipe'].toString();
            String symbol = tipe == 'tambah' ? '+' : '-';

            await printer.printLeftRight(
              '$symbol $jenis',
              formatter.format(biaya),
              0,
            );
          }

          double totalOperasional = 0.0;
          for (var op in operasionals) {
            double biaya = 0.0;
            if (op['biaya'] is double) {
              biaya = op['biaya'] as double;
            } else if (op['biaya'] is int) {
              biaya = (op['biaya'] as int).toDouble();
            } else {
              biaya = double.tryParse(op['biaya'].toString()) ?? 0.0;
            }

            if (op['tipe'] == 'tambah') {
              totalOperasional += biaya;
            } else {
              totalOperasional -= biaya;
            }
          }

          String totalOpStr = formatter.format(totalOperasional.round());
          totalOpStr = totalOpStr.trim();
          await printer.printLeftRight('Jml Operasional', totalOpStr, 1);
        }

        await printer.printCustom('========================', 1, 1);

        // TOTAL AKHIR - FIXED: Type conversion
        double totalAkhir = totalHrg;
        for (var op in operasionals) {
          double biaya = 0.0;
          if (op['biaya'] is double) {
            biaya = op['biaya'] as double;
          } else if (op['biaya'] is int) {
            biaya = (op['biaya'] as int).toDouble();
          } else {
            biaya = double.tryParse(op['biaya'].toString()) ?? 0.0;
          }

          if (op['tipe'] == 'tambah') {
            totalAkhir += biaya;
          } else {
            totalAkhir -= biaya;
          }
        }

        String nilaiFormatted = formatter.format(totalAkhir.round());
        String barisTotal =
            'TOTAL AKHIR'.padRight(20) + nilaiFormatted.padLeft(12);
        await printer.printCustom(barisTotal, 1, 2);
        await printer.printNewLine();

        // FOOTER
        await printer.printCustom(footerText, 0, 1);

        await printer.printNewLine();
        await printer.printNewLine();
        await printer.printNewLine();

        await printer.paperCut();

        if (duplicatePrint) {
          await Future.delayed(Duration(seconds: 2));
          await _cetakStrukLangsung();
        }

        await Future.delayed(Duration(milliseconds: 500));
        await printer.disconnect();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Struk berhasil dicetak'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        resetForm();
      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print('Printing connection error: $e');
        rethrow;
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
    }
  }

  // Fungsi untuk cek permission Bluetooth
  Future<bool> _checkBluetoothPermissions() async {
    try {
      if (await Permission.bluetoothConnect.request().isGranted &&
          await Permission.bluetoothScan.request().isGranted &&
          await Permission.locationWhenInUse.request().isGranted) {
        return true;
      }

      if (await Permission.bluetooth.request().isGranted &&
          await Permission.location.request().isGranted) {
        return true;
      }

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

  // Fungsi untuk membatalkan transaksi yang sedang berjalan
  void _handleBatalTransaksi() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Batalkan Transaksi'),
          content: Text(
            'Apakah Anda yakin ingin membatalkan transaksi ini? '
            'Semua data yang belum disimpan akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetForm();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transaksi telah dibatalkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHargaTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jenis Harga:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildHargaTypeChip('Um', HargaType.umum),
            _buildHargaTypeChip('Lv 1', HargaType.level1),
            _buildHargaTypeChip('Lv 2', HargaType.level2),
            _buildHargaTypeChip('Lv 3', HargaType.level3),
          ],
        ),
        SizedBox(height: 12),
        if (selectedKayuId != null)
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Harga saat ini: ${_getHargaTypeLabel()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHargaTypeChip(String label, HargaType type) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedHargaType == type,
      onSelected: (selected) {
        setState(() {
          selectedHargaType = type;
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: selectedHargaType == type ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Data dari Nota Fisik'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              if (data.isNotEmpty) {
                await _saveCurrentTransaction();
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PengaturanPage()),
              ).then((_) {
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
                    Text('Penjual: ${penjual.isNotEmpty ? penjual : "-"}'),
                    Text('Kayu: ${kayu.isNotEmpty ? kayu : "-"}'),
                    SizedBox(height: 4),
                    Text(
                      'Jenis Harga: ${_getHargaTypeLabel()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
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
                  flex: 2,
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
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jml Btg:'),
                      TextField(
                        controller: jumlahBatangController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Jml',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => jumlahBatang = value),
                        onTap: () {
                          jumlahBatangController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: jumlahBatangController.text.length,
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

            Text(
              'Data Transaksi Pembelian:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FlexColumnWidth(1.1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1.1),
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
                          0: FlexColumnWidth(1.1),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                          5: FlexColumnWidth(1.1),
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
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(getShortLabel(item['kriteria'])),
                                      ],
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
                                    child: Text(
                                      item['harga'].toInt().toString(),
                                    ),
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

            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleBatalTransaksi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
                      foregroundColor: const Color.fromARGB(
                        255,
                        114,
                        114,
                        114,
                      ), // warna teks & icon
                      minimumSize: Size.fromHeight(50),
                    ),
                    child: Text(
                      'BATAL / BARU',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 95, 28, 28),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSimpanTransaksi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size.fromHeight(50),
                    ),
                    child: Text(
                      'SIMPAN & CETAK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

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
                      'Input Data Pembelian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('No Faktur: $noFaktur'),
                    SizedBox(height: 10),

                    // Pilihan Jenis Harga hanya ada di modal
                    _buildHargaTypeSelector(),
                    SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Pilih Penjual',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedPenjualId,
                      items: daftarPenjual.map<DropdownMenuItem<String>>((
                        penjual,
                      ) {
                        final idStr = penjual['id']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: idStr,
                          child: Text(penjual['nama']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          selectedPenjualId = value;
                          final selected = daftarPenjual.firstWhere(
                            (p) => p['id']?.toString() == value,
                            orElse: () => <String, dynamic>{},
                          );
                          if (selected.isNotEmpty) {
                            selectedPenjualNama = selected['nama']?.toString();
                            selectedPenjualAlamat = selected['alamat']
                                ?.toString();
                            penjual = selectedPenjualNama ?? '';
                            alamat = selectedPenjualAlamat ?? '';
                          }
                        });
                      },
                    ),

                    SizedBox(height: 10),
                    Text('Alamat: ${selectedPenjualAlamat ?? ''}'),
                    SizedBox(height: 10),

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

                            harga = {
                              'Rijek 1': selected['harga_rijek_1'] ?? 0,
                              'Rijek 2': selected['harga_rijek_2'] ?? 0,
                              'Standar': selected['harga_standar'] ?? 0,
                              'Super A': selected['harga_super_a'] ?? 0,
                              'Super B': selected['harga_super_b'] ?? 0,
                              'Super C': selected['harga_super_c'] ?? 0,
                            };

                            hargaLevel1 = {
                              'Rijek 1': selected['harga_rijek_1_level1'] ?? 0,
                              'Rijek 2': selected['harga_rijek_2_level1'] ?? 0,
                              'Standar': selected['harga_standar_level1'] ?? 0,
                              'Super A': selected['harga_super_a_level1'] ?? 0,
                              'Super B': selected['harga_super_b_level1'] ?? 0,
                              'Super C': selected['harga_super_c_level1'] ?? 0,
                            };

                            hargaLevel2 = {
                              'Rijek 1': selected['harga_rijek_1_level2'] ?? 0,
                              'Rijek 2': selected['harga_rijek_2_level2'] ?? 0,
                              'Standar': selected['harga_standar_level2'] ?? 0,
                              'Super A': selected['harga_super_a_level2'] ?? 0,
                              'Super B': selected['harga_super_b_level2'] ?? 0,
                              'Super C': selected['harga_super_c_level2'] ?? 0,
                            };

                            hargaLevel3 = {
                              'Rijek 1': selected['harga_rijek_1_level3'] ?? 0,
                              'Rijek 2': selected['harga_rijek_2_level3'] ?? 0,
                              'Standar': selected['harga_standar_level3'] ?? 0,
                              'Super A': selected['harga_super_a_level3'] ?? 0,
                              'Super B': selected['harga_super_b_level3'] ?? 0,
                              'Super C': selected['harga_super_c_level3'] ?? 0,
                            };
                          }
                        });
                      },
                    ),

                    if (selectedKayuId != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Harga ${_getHargaTypeLabel()}:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...[
                            'Rijek 1',
                            'Rijek 2',
                            'Standar',
                            'Super A',
                            'Super B',
                            'Super C',
                          ].map((kriteria) {
                            double hargaValue = _getHargaBerdasarkanType(
                              kriteria,
                            );
                            if (hargaValue > 0) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '$kriteria: Rp ${hargaValue.toInt()}',
                                  style: TextStyle(fontSize: 13),
                                ),
                              );
                            }
                            return SizedBox();
                          }).toList(),
                        ],
                      ),

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
                              if (selectedPenjualId != null &&
                                  selectedKayuId != null) {
                                setState(() {
                                  modalVisible = false;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Pilih penjual dan jenis kayu terlebih dahulu',
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
