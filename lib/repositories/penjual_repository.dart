import 'package:tpk_app/models/penjual_model.dart';
import 'package:tpk_app/services/database_service.dart';

class PenjualRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Penjual>> getAllPenjual() async {
    final db = await _databaseService.database;
    final maps = await db.query('penjual', orderBy: 'nama ASC');
    return maps.map((map) => Penjual.fromMap(map)).toList();
  }

  Future<Penjual?> getPenjualById(int id) async {
    final db = await _databaseService.database;
    final maps = await db.query('penjual', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Penjual.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertPenjual(Penjual penjual) async {
    final db = await _databaseService.database;
    return await db.insert('penjual', penjual.toMap());
  }

  Future<int> updatePenjual(Penjual penjual) async {
    final db = await _databaseService.database;
    return await db.update(
      'penjual',
      penjual.toMap(),
      where: 'id = ?',
      whereArgs: [penjual.id],
    );
  }

  Future<int> deletePenjual(int id) async {
    final db = await _databaseService.database;
    return await db.delete('penjual', where: 'id = ?', whereArgs: [id]);
  }

  // Method untuk search penjual
  Future<List<Penjual>> searchPenjual(String query) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'penjual',
      where: 'nama LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'nama ASC',
    );
    return maps.map((map) => Penjual.fromMap(map)).toList();
  }
}
