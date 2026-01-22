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

class TransaksiOperNotaPage extends StatefulWidget {
  const TransaksiOperNotaPage({super.key});

  @override
  _TransaksiOperNotaPageState createState() => _TransaksiOperNotaPageState();
}

class _TransaksiOperNotaPageState extends State<TransaksiOperNotaPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Variabel untuk modal
  bool modalVisible = false;
  String noFaktur = '';
  String pembeli = '';
  String alamat = '';
  String kayu = '';
  String fakturPembelian = ''; // Tambahkan field untuk faktur pembelian

  // Harga jual berdasarkan pembeli
  Map<String, dynamic> harga = {
    'Rijek 1': 0.0,
    'Rijek 2': 0.0,
    'Standar': 0.0,
    'Super A': 0.0,
    'Super B': 0.0,
    'Super C': 0.0,
  };

  // Input data
  String diameter = '';
  String panjang = '';
  List<Map<String, dynamic>> data = [];
  String? latestItemId;

  // Custom volumes
  List<Map<String, dynamic>> customVolumes = [];
  String customDiameter = '';
  String customVolumeValue = '';

  // Custom kriteria
  String? selectedCustomKriteria;

  // Scroll controller
  ScrollController _scrollController = ScrollController();

  // Services
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefs = PreferencesService();

  // Data dari database
  List<Map<String, dynamic>> daftarPembeli = [];
  List<Map<String, dynamic>> daftarKayu = [];
  List<Map<String, dynamic>> daftarFakturPembelian =
      []; // Daftar faktur pembelian
  String? selectedPembeliId;
  String? selectedKayuId;
  String? selectedFakturPembelian; // Faktur pembelian yang dipilih
  String? selectedPembeliNama;
  String? selectedPembeliAlamat;
  String? selectedKayuNama;

  // Operasional
  List<Map<String, dynamic>> operasionals = [];
  TextEditingController operasionalJenisController = TextEditingController();
  TextEditingController operasionalBiayaController = TextEditingController();
  String operasionalTipe = 'tambah';

  // Controllers
  TextEditingController diameterController = TextEditingController();
  TextEditingController panjangController = TextEditingController();
  TextEditingController customDiameterController = TextEditingController();
  TextEditingController customVolumeController = TextEditingController();
  TextEditingController fakturPembelianController =
      TextEditingController(); // Controller untuk faktur pembelian

  // Formatter
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
    customDiameterController.dispose();
    customVolumeController.dispose();
    fakturPembelianController.dispose();
    operasionalJenisController.dispose();
    operasionalBiayaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void resetForm() {
    setState(() {
      panjangController.clear();
      diameterController.clear();
      customDiameterController.clear();
      customVolumeController.clear();
      fakturPembelianController.clear();
      operasionalJenisController.clear();
      operasionalBiayaController.clear();

      selectedCustomKriteria = null;
      selectedPembeliId = null;
      selectedPembeliNama = null;
      selectedPembeliAlamat = null;
      selectedKayuId = null;
      selectedKayuNama = null;
      selectedFakturPembelian = null;

      pembeli = '';
      alamat = '';
      kayu = '';
      fakturPembelian = '';
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
    _clearSavedTransaction();
  }

  double get totalVolume {
    return data.fold(0, (sum, item) => sum + (item['volume'] * item['jumlah']));
  }

  double get totalHarga {
    return data.fold(0, (sum, item) => sum + item['jumlahHarga']);
  }

  // Fungsi untuk memuat data dari database
  Future<void> _loadDataDariDatabase() async {
    await _loadPembeli();
    await _loadFakturPembelian(); // Memuat daftar faktur pembelian
  }

  // Fungsi untuk memuat data pembeli
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

  // Fungsi untuk memuat daftar faktur pembelian
  Future<void> _loadFakturPembelian() async {
    try {
      final db = await _dbService.database;
      final fakturData = await db.query(
        'pembelian',
        columns: ['faktur_pemb'],
        orderBy: 'id DESC',
      );

      setState(() {
        daftarFakturPembelian = fakturData
            .map((item) => {'faktur_pemb': item['faktur_pemb'] ?? ''})
            .toList();
      });
    } catch (error) {
      print('Error loading faktur pembelian: $error');
    }
  }

  // Fungsi untuk memuat detail pembelian berdasarkan faktur
  Future<void> _loadDetailPembelian(String faktur) async {
    try {
      final db = await _dbService.database;

      // Ambil data pembelian
      final pembelianData = await db.query(
        'pembelian',
        where: 'faktur_pemb = ?',
        whereArgs: [faktur],
      );

      if (pembelianData.isNotEmpty) {
        final pembelian = pembelianData.first;
        final productId = pembelian['product_id'];

        // Ambil detail pembelian
        final detailData = await db.query(
          'pembelian_detail',
          where: 'faktur_pemb = ?',
          whereArgs: [faktur],
        );

        if (detailData.isNotEmpty) {
          // Ambil nama kayu dari detail pertama
          final detail = detailData.first;
          final namaKayu = detail['nama_kayu'] as String? ?? '';

          setState(() {
            kayu = namaKayu;
            selectedKayuNama = namaKayu;

            // Kosongkan data sebelum menambahkan yang baru
            data.clear();

            // Tambahkan semua item dari pembelian ke data transaksi
            for (var item in detailData) {
              final newItem = {
                'id':
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    "_${item['id']}",
                'kriteria': item['kriteria'] ?? '',
                'diameter': (item['diameter'] as int?)?.toDouble() ?? 0.0,
                'panjang': (item['panjang'] as int?)?.toDouble() ?? 0.0,
                'jumlah': item['jumlah'] ?? 1,
                'volume': (item['volume'] as num?)?.toDouble() ?? 0.0,
                'harga': 0, // Harga akan diisi berdasarkan harga jual pembeli
                'jumlahHarga': 0, // Akan dihitung setelah harga ditentukan
                'from_pembelian':
                    true, // Flag bahwa item berasal dari pembelian
                'pembelian_detail_id': item['id'], // Simpan ID detail pembelian
              };

              data.add(newItem);
            }

            // Sort data
            data = sortData(data);
          });

          // Set faktur pembelian di controller
          fakturPembelianController.text = faktur;
          fakturPembelian = faktur;
          selectedFakturPembelian = faktur;
        }
      }
    } catch (error) {
      print('Error loading detail pembelian: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data pembelian: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk memuat harga jual berdasarkan pembeli
  Future<void> _loadHargaJualByPembeli(String? pembeliId) async {
    try {
      if (pembeliId == null || pembeliId.isEmpty) {
        setState(() {
          daftarKayu = [];
        });
        return;
      }

      final db = await _dbService.database;
      final kayuData = await db.rawQuery(
        '''
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
        ''',
        [int.parse(pembeliId)],
      );

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

  // Generate nomor faktur baru untuk penjualan
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

  // Fungsi utama untuk menambah atau update item
  void handleAddOrUpdate() {
    // Validasi: Pilih pembeli terlebih dahulu
    if (selectedPembeliId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih pembeli terlebih dahulu di "Input Data"'),
          backgroundColor: Colors.orange,
        ),
      );

      if (!modalVisible) {
        setState(() {
          modalVisible = true;
        });
      }
      return;
    }

    // Validasi: Pilih kayu terlebih dahulu
    if (kayu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih jenis kayu terlebih dahulu di "Input Data"'),
          backgroundColor: Colors.orange,
        ),
      );

      if (!modalVisible) {
        setState(() {
          modalVisible = true;
        });
      }
      return;
    }

    // Validasi: Harga harus ada
    if ((harga['Rijek 1'] ?? 0) == 0 &&
        (harga['Rijek 2'] ?? 0) == 0 &&
        (harga['Standar'] ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga belum diatur untuk pembeli ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi: Input diameter dan panjang
    if (diameter.isEmpty || panjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan diameter dan panjang'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    double d = double.tryParse(diameter) ?? 0;
    double p = double.tryParse(panjang) ?? 0;
    if (d == 0 || p == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diameter dan panjang harus lebih dari 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tentukan kriteria berdasarkan diameter atau custom
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

    // Ambil harga berdasarkan kriteria
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
        'harga': hargaSatuan, // Update harga sesuai dengan harga jual pembeli
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
        'harga': hargaSatuan, // Harga dari harga jual pembeli
        'jumlahHarga': jumlahHarga,
        'from_pembelian': false, // Item baru, bukan dari pembelian
      };
      updatedData = sortData([...data, newItem]);
      setState(() {
        latestItemId = newItem['id'].toString();
        data = updatedData;
      });
    }

    // Clear input fields
    diameterController.clear();
    panjangController.clear();
    setState(() {
      diameter = '';
      panjang = '';
    });

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

  // Fungsi untuk mengaplikasikan harga ke semua item yang sudah ada
  void applyHargaToAllItems() {
    _debugHarga(); // Tambahkan ini untuk debugging
    if (selectedPembeliId == null || selectedPembeliNama == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih pembeli terlebih dahulu di "Input Data"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (harga.isEmpty || data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada data harga atau item transaksi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Cek apakah ada harga yang valid
    bool hasValidPrice = false;
    for (var key in harga.keys) {
      dynamic priceValue = harga[key];
      if (priceValue is num && priceValue > 0) {
        hasValidPrice = true;
        break;
      } else if (priceValue is String &&
          double.tryParse(priceValue) != null &&
          double.tryParse(priceValue)! > 0) {
        hasValidPrice = true;
        break;
      }
    }

    if (!hasValidPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harga belum diatur untuk pembeli ini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      data = data.map((item) {
        String kriteria = item['kriteria'];
        dynamic rawHargaItem = harga[kriteria] ?? 0;
        double hargaDouble = 0;

        if (rawHargaItem is String) {
          hargaDouble = double.tryParse(rawHargaItem) ?? 0;
        } else if (rawHargaItem is int) {
          hargaDouble = rawHargaItem.toDouble();
        } else if (rawHargaItem is double) {
          hargaDouble = rawHargaItem;
        }

        int hargaSatuan = hargaDouble.round();
        double volume = (item['volume'] as num?)?.toDouble() ?? 0.0;
        int jumlah = (item['jumlah'] as int?) ?? 1;

        return {
          ...item,
          'harga': hargaSatuan,
          'jumlahHarga': (volume * hargaSatuan * jumlah).round(),
        };
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Harga berhasil diterapkan ke semua item'),
        backgroundColor: Colors.green,
      ),
    );
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

  // Fungsi untuk memuat transaksi yang tersimpan
  Future<void> _loadSavedTransaction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('current_opernota_transaction');

      if (savedData != null && savedData.isNotEmpty) {
        final transactionData = json.decode(savedData) as Map<String, dynamic>;

        setState(() {
          noFaktur = transactionData['noFaktur'] ?? noFaktur;
          pembeli = transactionData['pembeli'] ?? '';
          alamat = transactionData['alamat'] ?? '';
          kayu = transactionData['kayu'] ?? '';
          fakturPembelian = transactionData['fakturPembelian'] ?? '';
          selectedPembeliId = transactionData['selectedPembeliId'];
          selectedPembeliNama = transactionData['selectedPembeliNama'];
          selectedPembeliAlamat = transactionData['selectedPembeliAlamat'];
          selectedKayuId = transactionData['selectedKayuId'];
          selectedKayuNama = transactionData['selectedKayuNama'];
          selectedFakturPembelian = transactionData['selectedFakturPembelian'];

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
          fakturPembelianController.text = fakturPembelian;
        });
      }
    } catch (e) {
      print('Error loading saved transaction: $e');
    }
  }

  // Fungsi untuk menghapus transaksi yang tersimpan
  Future<void> _clearSavedTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_opernota_transaction');
  }

  // Fungsi untuk menyimpan transaksi yang sedang berlangsung
  Future<void> _saveCurrentTransaction() async {
    try {
      Map<String, dynamic> transactionData = {
        'noFaktur': noFaktur,
        'pembeli': pembeli,
        'alamat': alamat,
        'kayu': kayu,
        'fakturPembelian': fakturPembelian,
        'selectedPembeliId': selectedPembeliId,
        'selectedPembeliNama': selectedPembeliNama,
        'selectedPembeliAlamat': selectedPembeliAlamat,
        'selectedKayuId': selectedKayuId,
        'selectedKayuNama': selectedKayuNama,
        'selectedFakturPembelian': selectedFakturPembelian,
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
        'current_opernota_transaction',
        json.encode(transactionData),
      );
    } catch (e) {
      print('Error saving transaction: $e');
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

  // Fungsi untuk menyimpan ke database
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

        // 4. Update stok (mengurangi stok karena penjualan)
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
            final newStok = currentStok - item['jumlah'];
            await txn.update(
              'stok',
              {
                'stok_buku': newStok >= 0 ? newStok : 0,
                'updated_at': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [existingStok.first['id']],
            );
          } else {
            // Jika stok tidak ada, buat record dengan nilai negatif (ini seharusnya tidak terjadi)
            await txn.insert('stok', {
              'nama_kayu': kayu,
              'kriteria': item['kriteria'],
              'diameter': item['diameter'],
              'panjang': item['panjang'],
              'stok_buku':
                  -item['jumlah'], // Nilai negatif karena penjualan tanpa stok awal
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

  // Fungsi utama untuk simpan transaksi
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
        return;
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

  // Fungsi untuk mencetak struk (sama seperti transaksi penjualan biasa)
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

      // Cek permission Bluetooth
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
        // Cek status koneksi
        bool? isConnected = await printer.isConnected;

        // Jika sudah terhubung ke device lain, putuskan dulu
        if (isConnected == true) {
          await printer.disconnect();
          await Future.delayed(Duration(milliseconds: 500));
        }

        // Coba koneksi ke printer
        await printer.connect(targetDevice);
        await Future.delayed(Duration(milliseconds: 1500));

        // Verifikasi koneksi
        isConnected = await printer.isConnected;

        if (isConnected != true) {
          Navigator.pop(context);
          throw Exception(
            'Gagal terhubung ke printer. Pastikan printer dalam keadaan ON dan sudah dipasangkan (paired).',
          );
        }

        Navigator.pop(context);

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

        // Tampilkan faktur pembelian jika ada
        if (fakturPembelian.isNotEmpty) {
          String fakturPembelianLine =
              'Ref Pembelian'.padRight(lineWidth - fakturPembelian.length) +
              fakturPembelian;
          await printer.printCustom(fakturPembelianLine, 1, 0);
        }

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
          await printer.printCustom(detail, 1, 2);
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

        // BIAYA OPERASIONAL
        if (operasionals.isNotEmpty) {
          await printer.printCustom('------------------------', 1, 1);
          await printer.printCustom('BIAYA OPERASIONAL:', 1, 0);

          for (var op in operasionals) {
            String jenis = op['jenis'].toString();
            int biaya = int.tryParse(op['biaya'].toString()) ?? 0;
            String tipe = op['tipe'].toString();
            String symbol = tipe == 'tambah' ? '+' : '-';

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
          totalOpStr = totalOpStr.trim();
          await printer.printLeftRight('Jml Operasional', totalOpStr, 1);
        }

        await printer.printCustom('========================', 1, 1);

        // TOTAL AKHIR
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
          await _cetakStrukLangsung();
        }

        // Putuskan koneksi setelah selesai
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

  // Fungsi untuk debugging harga
  void _debugHarga() {
    print('=== DEBUG HARGA ===');
    print('selectedPembeliId: $selectedPembeliId');
    print('selectedPembeliNama: $selectedPembeliNama');
    print('selectedKayuId: $selectedKayuId');
    print('selectedKayuNama: $selectedKayuNama');
    print('Harga Map:');
    harga.forEach((key, value) {
      print('  $key: $value (type: ${value.runtimeType})');
    });
    print('Data items count: ${data.length}');
    if (data.isNotEmpty) {
      print('Item pertama kriteria: ${data.first['kriteria']}');
      print('Item pertama harga: ${data.first['harga']}');
    }
    print('==================');
  }

  // Helper function untuk mencari item berdasarkan ID
  Map<String, dynamic> _findItemById(List<dynamic> list, String? id) {
    if (id == null) return {};

    for (var item in list) {
      if (item is Map<String, dynamic> && item['id']?.toString() == id) {
        return Map<String, dynamic>.from(item);
      }
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi Oper Nota'),
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
                    if (fakturPembelian.isNotEmpty)
                      Text('Ref: $fakturPembelian'),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // Tombol untuk memuat data dari pembelian
            if (daftarFakturPembelian.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ambil Data dari Pembelian:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                ],
              ),

            // Input manual faktur pembelian
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fakturPembelianController,
                    decoration: InputDecoration(
                      labelText: 'No Faktur Pembelian',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan nomor faktur pembelian',
                    ),
                    onChanged: (value) =>
                        setState(() => fakturPembelian = value),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (fakturPembelianController.text.isNotEmpty) {
                      _loadDetailPembelian(fakturPembelianController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Masukkan faktur pembelian terlebih dahulu',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Text('Load Data'),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Tombol untuk mengaplikasikan harga ke semua item
            if (data.isNotEmpty && selectedPembeliId != null)
              ElevatedButton(
                onPressed: applyHargaToAllItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Terapkan Harga ke Semua Item'),
              ),

            SizedBox(height: 10),

            // Tabel Data Transaksi
            Text(
              'Data Transaksi Oper Nota:',
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
                            'Jml Vol',
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
                    int jumlahVolume = (item['volume'] * item['jumlah'])
                        .round(); // Hitung Jml Vol
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
                                    child: Text(
                                      jumlahVolume
                                          .toString(), // Menampilkan Jml Vol
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

            // Tombol Aksi
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
                            selectedPembeliAlamat = selected['alamat']
                                ?.toString();
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
                      // Modifikasi onChanged di dropdown kayu tetap sama:
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
                                // Gunakan fungsi helper
                                final selectedPembeli = _findItemById(
                                  daftarPembeli,
                                  selectedPembeliId,
                                );
                                final selectedKayu = _findItemById(
                                  daftarKayu,
                                  selectedKayuId,
                                );

                                if (selectedPembeli.isNotEmpty &&
                                    selectedKayu.isNotEmpty) {
                                  setState(() {
                                    pembeli =
                                        selectedPembeli['nama']?.toString() ??
                                        '';
                                    alamat =
                                        selectedPembeli['alamat']?.toString() ??
                                        '';
                                    kayu =
                                        selectedKayu['nama_kayu']?.toString() ??
                                        '';

                                    harga = {
                                      'Rijek 1':
                                          selectedKayu['harga_rijek_1'] ?? 0,
                                      'Rijek 2':
                                          selectedKayu['harga_rijek_2'] ?? 0,
                                      'Standar':
                                          selectedKayu['harga_standar'] ?? 0,
                                      'Super A':
                                          selectedKayu['harga_super_a'] ?? 0,
                                      'Super B':
                                          selectedKayu['harga_super_b'] ?? 0,
                                      'Super C':
                                          selectedKayu['harga_super_c'] ?? 0,
                                    };

                                    modalVisible = false;
                                  });

                                  print('✅ Modal disimpan - Kayu: "$kayu"');
                                  _saveCurrentTransaction();
                                }
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
