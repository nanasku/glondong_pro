import 'package:tpk_app/services/database_service.dart';

class HargaBeliRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Map<String, dynamic>>> getAllHargaBeli() async {
    final db = await _databaseService.database;
    return await db.query('harga_beli', orderBy: 'nama_kayu ASC');
  }

  Future<int> updateHargaBeli(Map<String, dynamic> hargaBeli) async {
    final db = await _databaseService.database;
    return await db.update(
      'harga_beli',
      hargaBeli,
      where: 'id = ?',
      whereArgs: [hargaBeli['id']],
    );
  }
}
