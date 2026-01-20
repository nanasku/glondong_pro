import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const int _databaseVersion = 2; // Naikkan version dari 1 ke 2

  // Getter database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tpk.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase, // Tambahkan ini
    );
  }

  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Tambahkan tabel biaya_lain untuk upgrade dari version 1 ke 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS biaya_lain (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tanggal TEXT NOT NULL,
          jenis_biaya TEXT NOT NULL,
          jumlah_biaya INTEGER NOT NULL DEFAULT 0,
          keterangan TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE printer_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur TEXT,
        printer_name TEXT,
        printer_type TEXT,
        printed_at TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT,
        error_message TEXT
      )
    ''');

    // Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        company_name TEXT NOT NULL,
        alamat TEXT,
        profile_image TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Harga Beli
    await db.execute('''
      CREATE TABLE harga_beli (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kayu TEXT NOT NULL,
        harga_rijek_1 INTEGER DEFAULT 0,
        harga_rijek_2 INTEGER DEFAULT 0,
        harga_standar INTEGER DEFAULT 0,
        harga_super_a INTEGER DEFAULT 0,
        harga_super_b INTEGER DEFAULT 0,
        harga_super_c INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Harga Jual
    await db.execute('''
      CREATE TABLE harga_jual (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kayu TEXT NOT NULL,
        harga_rijek_1 INTEGER DEFAULT 0,
        harga_rijek_2 INTEGER DEFAULT 0,
        harga_standar INTEGER DEFAULT 0,
        harga_super_a INTEGER DEFAULT 0,
        harga_super_b INTEGER DEFAULT 0,
        harga_super_c INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Penjual
    await db.execute('''
      CREATE TABLE penjual (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        alamat TEXT,
        telepon TEXT,
        email TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Pembeli
    await db.execute('''
      CREATE TABLE pembeli (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        alamat TEXT,
        telepon TEXT,
        email TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Pembelian
    await db.execute('''
      CREATE TABLE pembelian (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_pemb TEXT UNIQUE NOT NULL,
        penjual_id INTEGER,
        product_id INTEGER,
        total INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (penjual_id) REFERENCES penjual (id)
      )
    ''');

    // Pembelian Detail
    await db.execute('''
      CREATE TABLE pembelian_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_pemb TEXT NOT NULL,
        nama_kayu TEXT NOT NULL,
        kriteria TEXT NOT NULL,
        diameter INTEGER NOT NULL,
        panjang INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        volume REAL NOT NULL,
        harga_beli INTEGER NOT NULL,
        jumlah_harga_beli INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (faktur_pemb) REFERENCES pembelian (faktur_pemb)
      )
    ''');

    // Pembelian Operasional
    await db.execute('''
      CREATE TABLE pembelian_operasional (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_pemb TEXT NOT NULL,
        jenis TEXT NOT NULL,
        biaya INTEGER NOT NULL DEFAULT 0,
        tipe TEXT CHECK(tipe IN ('tambah', 'kurang')) DEFAULT 'tambah',
        FOREIGN KEY (faktur_pemb) REFERENCES pembelian (faktur_pemb)
      )
    ''');

    // Penjualan
    await db.execute('''
      CREATE TABLE penjualan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_penj TEXT UNIQUE NOT NULL,
        pembeli_id INTEGER,
        product_id INTEGER,
        total INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (pembeli_id) REFERENCES pembeli (id)
      )
    ''');

    // Penjualan Detail
    await db.execute('''
      CREATE TABLE penjualan_detail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_penj TEXT NOT NULL,
        nama_kayu TEXT NOT NULL,
        kriteria TEXT NOT NULL,
        diameter INTEGER NOT NULL,
        panjang INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        volume REAL NOT NULL,
        harga_jual INTEGER NOT NULL,
        jumlah_harga_jual INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (faktur_penj) REFERENCES penjualan (faktur_penj)
      )
    ''');

    // Penjualan Operasional
    await db.execute('''
      CREATE TABLE penjualan_operasional (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        faktur_penj TEXT NOT NULL,
        jenis TEXT NOT NULL,
        biaya INTEGER NOT NULL DEFAULT 0,
        tipe TEXT CHECK(tipe IN ('tambah', 'kurang')) DEFAULT 'tambah',
        FOREIGN KEY (faktur_penj) REFERENCES penjualan (faktur_penj)
      )
    ''');

    // Stok
    await db.execute('''
      CREATE TABLE stok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kayu TEXT NOT NULL,
        kriteria TEXT NOT NULL,
        diameter INTEGER NOT NULL,
        panjang INTEGER NOT NULL,
        stok_buku INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(nama_kayu, kriteria, diameter, panjang)
      )
    ''');

    // Stok Awal
    await db.execute('''
      CREATE TABLE stok_awal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kayu TEXT NOT NULL,
        kriteria TEXT NOT NULL,
        diameter INTEGER NOT NULL,
        panjang INTEGER NOT NULL,
        bulan INTEGER NOT NULL,
        periode_bulan INTEGER NOT NULL,
        stok_awal INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Stok Opname
    await db.execute('''
      CREATE TABLE stok_opname (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kayu TEXT NOT NULL,
        kriteria TEXT NOT NULL,
        diameter INTEGER NOT NULL,
        panjang INTEGER NOT NULL,
        stok_buku INTEGER NOT NULL,
        stok_opname INTEGER NOT NULL,
        stok_rusak INTEGER DEFAULT 0,
        selisih INTEGER,
        tanggal_opname TEXT NOT NULL,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Biaya Lain - TAMBAHKAN DI SINI
    await db.execute('''
      CREATE TABLE biaya_lain (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        jenis_biaya TEXT NOT NULL,
        jumlah_biaya INTEGER NOT NULL DEFAULT 0,
        keterangan TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // TAMBAHKAN tabel untuk sistem aktivasi
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_activation (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_serial TEXT NOT NULL UNIQUE,
        activation_code TEXT NOT NULL,
        activation_date TEXT NOT NULL,
        status TEXT CHECK(status IN ('active', 'inactive', 'expired')) DEFAULT 'inactive',
        expiry_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _insertDefaultData(db);
  }

  static Future<void> _insertDefaultData(Database db) async {
    final users = await db.query('users');
    if (users.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'email': 'admin@tpk.com',
        'password': 'password123',
        'company_name': 'TPK Company',
        'alamat': 'Alamat default perusahaan',
        'profile_image': 'default_profile.jpg',
      });
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    String path = join(await getDatabasesPath(), 'tpk.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
  }

  // =============== CRUD PENJUAL =============================
  // ==========================================================

  Future<int> insertPenjual(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('penjual', data);
  }

  Future<List<Map<String, dynamic>>> getAllPenjual() async {
    final db = await database;
    return await db.query('penjual', orderBy: 'id DESC');
  }

  Future<int> updatePenjual(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('penjual', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePenjual(int id) async {
    final db = await database;
    return await db.delete('penjual', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPenjualById(int id) async {
    final db = await database;
    final results = await db.query('penjual', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // =============== CRUD PEMBELI =============================
  // ==========================================================

  // Method untuk log printer
  Future<int> logPrinterPrint(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('printer_log', data);
  }

  Future<int> insertPembeli(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pembeli', data);
  }

  Future<List<Map<String, dynamic>>> getAllPembeli() async {
    final db = await database;
    return await db.query('pembeli', orderBy: 'id DESC');
  }

  Future<int> updatePembeli(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('pembeli', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePembeli(int id) async {
    final db = await database;
    return await db.delete('pembeli', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getPembeliById(int id) async {
    final db = await database;
    final results = await db.query('pembeli', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  // ========================= harga_beli =====================
  // ==========================================================
  Future<List<Map<String, dynamic>>> getAllHargaBeli() async {
    final db = await database;
    return await db.query('harga_beli', orderBy: 'nama_kayu ASC');
  }

  Future<Map<String, dynamic>?> getHargaBeliById(int id) async {
    final db = await database;
    final results = await db.query(
      'harga_beli',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertHargaBeli(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('harga_beli', data);
  }

  Future<int> updateHargaBeli(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'harga_beli',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHargaBeli(int id) async {
    final db = await database;
    return await db.delete('harga_beli', where: 'id = ?', whereArgs: [id]);
  }

  // ========================= harga_jual =====================
  // ==========================================================
  Future<List<Map<String, dynamic>>> getAllHargaJual() async {
    final db = await database;
    return await db.query('harga_jual', orderBy: 'nama_kayu ASC');
  }

  Future<Map<String, dynamic>?> getHargaJualById(int id) async {
    final db = await database;
    final results = await db.query(
      'harga_jual',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertHargaJual(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('harga_jual', data);
  }

  Future<int> updateHargaJual(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'harga_jual',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHargaJual(int id) async {
    final db = await database;
    return await db.delete('harga_jual', where: 'id = ?', whereArgs: [id]);
  }

  // =============== STATISTIK DASHBOARD ===================
  // ==========================================================

  // Jumlah pembelian hari ini
  Future<int> getPembelianHariIni() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as count FROM pembelian 
    WHERE created_at BETWEEN ? AND ?
  ''',
      [todayStart.toIso8601String(), todayEnd.toIso8601String()],
    );

    return result.first['count'] as int? ?? 0;
  }

  // Jumlah penjualan hari ini
  Future<int> getPenjualanHariIni() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as count FROM penjualan 
    WHERE created_at BETWEEN ? AND ?
  ''',
      [todayStart.toIso8601String(), todayEnd.toIso8601String()],
    );

    return result.first['count'] as int? ?? 0;
  }

  // Total jumlah batang saat ini (pembelian - penjualan)
  Future<int> getTotalBatang() async {
    final db = await database;

    try {
      // Hitung total jumlah batang dari semua pembelian
      final pembelianResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total_masuk 
      FROM pembelian_detail
    ''');

      // Hitung total jumlah batang dari semua penjualan
      final penjualanResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total_keluar 
      FROM penjualan_detail
    ''');

      final totalMasuk = pembelianResult.first['total_masuk'];
      final totalKeluar = penjualanResult.first['total_keluar'];

      int masuk = 0;
      int keluar = 0;

      // Handle type cast untuk total_masuk
      if (totalMasuk != null) {
        if (totalMasuk is int) {
          masuk = totalMasuk;
        } else if (totalMasuk is num) {
          masuk = totalMasuk.toInt();
        }
      }

      // Handle type cast untuk total_keluar
      if (totalKeluar != null) {
        if (totalKeluar is int) {
          keluar = totalKeluar;
        } else if (totalKeluar is num) {
          keluar = totalKeluar.toInt();
        }
      }

      // Total batang = pembelian - penjualan
      final totalBatang = masuk - keluar;

      print('Total batang: Masuk=$masuk, Keluar=$keluar, Stok=$totalBatang');

      return totalBatang > 0 ? totalBatang : 0;
    } catch (e) {
      print('Error in getTotalBatang: $e');
      return 0;
    }
  }

  // Total kubikasi stok saat ini (pembelian - penjualan) dalam cm³
  // Menggunakan rumus: jumlah × volume per item
  Future<double> getTotalVolumeCm3() async {
    final db = await database;

    try {
      // Hitung TOTAL VOLUME MASUK dari pembelian_detail (dalam cm³)
      // Sama dengan laporan: jumlah × volume
      final resultMasuk = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah * volume), 0) as total_masuk 
      FROM pembelian_detail
    ''');

      // Hitung TOTAL VOLUME KELUAR dari penjualan_detail (dalam cm³)
      // Sama dengan laporan: jumlah × volume
      final resultKeluar = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah * volume), 0) as total_keluar 
      FROM penjualan_detail
    ''');

      final totalMasuk = resultMasuk.first['total_masuk'];
      final totalKeluar = resultKeluar.first['total_keluar'];

      double masuk = 0.0;
      double keluar = 0.0;

      // Handle type cast untuk total_masuk
      if (totalMasuk != null) {
        if (totalMasuk is int) {
          masuk = totalMasuk.toDouble();
        } else if (totalMasuk is double) {
          masuk = totalMasuk;
        } else if (totalMasuk is num) {
          masuk = totalMasuk.toDouble();
        }
      }

      // Handle type cast untuk total_keluar
      if (totalKeluar != null) {
        if (totalKeluar is int) {
          keluar = totalKeluar.toDouble();
        } else if (totalKeluar is double) {
          keluar = totalKeluar;
        } else if (totalKeluar is num) {
          keluar = totalKeluar.toDouble();
        }
      }

      // Total Volume = pembelian - penjualan (dalam cm³)
      final totalVolumeCm3 = masuk - keluar;

      return totalVolumeCm3 > 0 ? totalVolumeCm3 : 0.0;
    } catch (e) {
      print('Error in getTotalVolumeCm3: $e');
      return 0.0;
    }
  }

  // Untuk dashboard, bisa tetap pakai yang mengembalikan m³
  Future<double> getTotalKubikasi() async {
    final totalVolumeCm3 = await getTotalVolumeCm3();
    // Konversi ke m³ (1 m³ = 1,000,000 cm³)
    return totalVolumeCm3 / 1000000;
  }

  // Method untuk mendapatkan detail perhitungan (untuk debugging)
  Future<Map<String, dynamic>> getDetailPerhitunganStok() async {
    final db = await database;

    try {
      // Hitung detail pembelian
      final pembelianDetail = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(jumlah), 0) as total_batang_masuk,
        COALESCE(SUM(jumlah * volume), 0) as total_volume_masuk_cm3,
        COUNT(*) as jumlah_transaksi_masuk
      FROM pembelian_detail
    ''');

      // Hitung detail penjualan
      final penjualanDetail = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(jumlah), 0) as total_batang_keluar,
        COALESCE(SUM(jumlah * volume), 0) as total_volume_keluar_cm3,
        COUNT(*) as jumlah_transaksi_keluar
      FROM penjualan_detail
    ''');

      final masuk = pembelianDetail.first;
      final keluar = penjualanDetail.first;

      final totalBatangMasuk = (masuk['total_batang_masuk'] as int?) ?? 0;
      final totalVolumeMasukCm3 =
          (masuk['total_volume_masuk_cm3'] as double?) ?? 0.0;
      final totalVolumeMasukM3 = totalVolumeMasukCm3 / 1000000;

      final totalBatangKeluar = (keluar['total_batang_keluar'] as int?) ?? 0;
      final totalVolumeKeluarCm3 =
          (keluar['total_volume_keluar_cm3'] as double?) ?? 0.0;
      final totalVolumeKeluarM3 = totalVolumeKeluarCm3 / 1000000;

      final stokBatang = totalBatangMasuk - totalBatangKeluar;
      final stokVolumeM3 = totalVolumeMasukM3 - totalVolumeKeluarM3;

      return {
        'pembelian': {
          'batang': totalBatangMasuk,
          'volume_cm3': totalVolumeMasukCm3,
          'volume_m3': totalVolumeMasukM3,
          'transaksi': masuk['jumlah_transaksi_masuk'] ?? 0,
        },
        'penjualan': {
          'batang': totalBatangKeluar,
          'volume_cm3': totalVolumeKeluarCm3,
          'volume_m3': totalVolumeKeluarM3,
          'transaksi': keluar['jumlah_transaksi_keluar'] ?? 0,
        },
        'stok': {
          'batang': stokBatang > 0 ? stokBatang : 0,
          'volume_m3': stokVolumeM3 > 0 ? stokVolumeM3 : 0.0,
        },
        'formula': 'Stok = Pembelian - Penjualan',
      };
    } catch (e) {
      print('Error in getDetailPerhitunganStok: $e');
      return {};
    }
  }

  // =============== CRUD BIAYA LAIN =========================
  // ==========================================================

  Future<int> insertBiayaLain(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('biaya_lain', data);
  }

  Future<List<Map<String, dynamic>>> getAllBiayaLain() async {
    final db = await database;
    return await db.query('biaya_lain', orderBy: 'tanggal DESC');
  }

  Future<List<Map<String, dynamic>>> getBiayaLainByBulanTahun(
    int bulan,
    int tahun,
  ) async {
    final db = await database;
    return await db.query(
      'biaya_lain',
      where: 'strftime("%m", tanggal) = ? AND strftime("%Y", tanggal) = ?',
      whereArgs: [bulan.toString().padLeft(2, '0'), tahun.toString()],
      orderBy: 'tanggal DESC',
    );
  }

  Future<int> updateBiayaLain(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'biaya_lain',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBiayaLain(int id) async {
    final db = await database;
    return await db.delete('biaya_lain', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getBiayaLainById(int id) async {
    final db = await database;
    final results = await db.query(
      'biaya_lain',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> getTotalBiayaLainByBulanTahun(int bulan, int tahun) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(jumlah_biaya), 0) as total 
    FROM biaya_lain 
    WHERE strftime("%m", tanggal) = ? AND strftime("%Y", tanggal) = ?
  ''',
      [bulan.toString().padLeft(2, '0'), tahun.toString()],
    );

    return result.first['total'] as int? ?? 0;
  }

  // Tambahkan method untuk sistem aktivasi di bagian akhir file
  // =============== SISTEM AKTIVASI =========================
  // ==========================================================

  Future<int> insertActivationRecord(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('app_activation', data);
  }

  Future<Map<String, dynamic>?> getActivationRecord() async {
    final db = await database;
    final results = await db.query('app_activation', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> isAppActivated() async {
    final record = await getActivationRecord();
    if (record == null) return false;

    final status = record['status'] as String?;
    final expiryDate = record['expiry_date'] as String?;

    // Cek status
    if (status != 'active') return false;

    // Cek expiry date jika ada
    if (expiryDate != null && expiryDate.isNotEmpty) {
      final now = DateTime.now();
      final expiry = DateTime.parse(expiryDate);
      if (now.isAfter(expiry)) {
        // Update status menjadi expired
        await updateActivationStatus('expired');
        return false;
      }
    }

    return true;
  }

  Future<int> updateActivationStatus(String status) async {
    final db = await database;
    return await db.update('app_activation', {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deleteActivationRecord() async {
    final db = await database;
    return await db.delete('app_activation');
  }

  // Method untuk verifikasi kode di database
  Future<bool> verifyActivationInDatabase(
    String deviceSerial,
    String activationCode,
  ) async {
    final db = await database;

    // Cari record berdasarkan device_serial dan activation_code
    final result = await db.rawQuery(
      '''
      SELECT * FROM app_activation 
      WHERE device_serial = ? AND activation_code = ? AND status = 'active'
    ''',
      [deviceSerial, activationCode],
    );

    return result.isNotEmpty;
  }

  // ==========================================================
  // ==========================================================
  Future<void> initializeDatabase() async {
    await database;
  }
}
