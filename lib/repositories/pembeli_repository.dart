import 'package:tpk_app/services/database_service.dart';

class PembeliRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Map<String, dynamic>>> getAllPembeli() async {
    final db = await _databaseService.database;
    return await db.query('pembeli', orderBy: 'nama ASC');
  }

  Future<int> insertPembeli(Map<String, dynamic> pembeli) async {
    final db = await _databaseService.database;
    return await db.insert('pembeli', pembeli);
  }

  // ... method lainnya
}
