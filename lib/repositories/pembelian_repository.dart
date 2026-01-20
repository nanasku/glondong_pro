import 'package:tpk_app/services/database_service.dart';

class PembelianRepository {
  final DatabaseService dbService = DatabaseService();

  Future<String> generateNoFaktur() async {
    final db = await dbService.database;
    final today = DateTime.now();
    final formattedDate =
        '${today.day.toString().padLeft(2, '0')}${today.month.toString().padLeft(2, '0')}${today.year}';

    final lastFaktur = await db.query(
      'pembelian',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (lastFaktur.isEmpty) {
      return 'PB-$formattedDate-0001';
    }

    final last = lastFaktur.first['faktur_pemb'] as String;
    final parts = last.split('-');

    if (parts.length != 3) {
      return 'PB-$formattedDate-0001';
    }

    final datePart = parts[1];
    final seqPart = parts[2];

    String newSeq;
    if (datePart == formattedDate) {
      newSeq = (int.parse(seqPart) + 1).toString().padLeft(4, '0');
    } else {
      newSeq = '0001';
    }

    return 'PB-$formattedDate-$newSeq';
  }

  Future<int> insertPembelianWithDetails({
    required Map<String, dynamic> pembelian,
    required List<Map<String, dynamic>> details,
    required List<Map<String, dynamic>> operasionals,
  }) async {
    final db = await dbService.database;

    return await db.transaction((txn) async {
      // Insert pembelian utama
      final pembelianId = await txn.insert('pembelian', pembelian);

      // Insert details
      for (final detail in details) {
        await txn.insert('pembelian_detail', detail);
      }

      // Insert operasionals
      for (final ops in operasionals) {
        await txn.insert('pembelian_operasional', ops);
      }

      // Recalculate total
      await _recalculateTotal(txn, pembelian['faktur_pemb']);

      return pembelianId;
    });
  }

  Future<void> _recalculateTotal( txn, String fakturPemb) async {
    // Calculate total from details
    final detailResult = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(jumlah_harga_beli), 0) as total_items 
      FROM pembelian_detail 
      WHERE faktur_pemb = ?
    ''',
      [fakturPemb],
    );

    final totalItems = detailResult.first['total_items'] as int? ?? 0;

    // Calculate total from operasionals
    final opsResult = await txn.rawQuery(
      '''
      SELECT COALESCE(SUM(
        CASE WHEN tipe = 'tambah' THEN biaya ELSE -biaya END
      ), 0) as total_ops 
      FROM pembelian_operasional 
      WHERE faktur_pemb = ?
    ''',
      [fakturPemb],
    );

    final totalOps = opsResult.first['total_ops'] as int? ?? 0;

    final finalTotal = totalItems + totalOps;

    // Update total in pembelian
    await txn.update(
      'pembelian',
      {'total': finalTotal},
      where: 'faktur_pemb = ?',
      whereArgs: [fakturPemb],
    );
  }

  Future<List<Map<String, dynamic>>> getLaporan({
    String? tanggal,
    String? bulan,
    String? tahun,
    int? penjualId,
  }) async {
    final db = await dbService.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (tanggal != null && tanggal.isNotEmpty) {
      whereClause += 'DATE(pb.created_at) = ?';
      whereArgs.add(tanggal);
    }

    if (bulan != null && bulan.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'strftime("%Y-%m", pb.created_at) = ?';
      whereArgs.add(bulan);
    }

    if (tahun != null && tahun.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'strftime("%Y", pb.created_at) = ?';
      whereArgs.add(tahun);
    }

    if (penjualId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'pb.penjual_id = ?';
      whereArgs.add(penjualId);
    }

    final query =
        '''
      SELECT 
        pb.*, 
        pl.nama AS nama_penjual,
        pl.alamat AS alamat_penjual,
        pl.telepon AS telepon_penjual
      FROM pembelian pb
      LEFT JOIN penjual pl ON pb.penjual_id = pl.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY pb.created_at DESC
    ''';

    return await db.rawQuery(query, whereArgs);
  }
}
