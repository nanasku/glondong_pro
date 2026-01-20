import 'package:tpk_app/models/user_model.dart';
import 'package:tpk_app/services/database_service.dart';

class UserRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<User?> getUserByEmail(String email) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertUser(User user) async {
    final db = await _databaseService.database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    final db = await _databaseService.database;

    // Buat map untuk update
    final Map<String, dynamic> updateData = {
      'username': user.username,
      'email': user.email, // PASTIKAN email diupdate
      'company_name': user.companyName,
      'alamat': user.alamat,
      'profile_image': user.profileImage,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Debug print
    print('=== DATABASE UPDATE ===');
    print('Table: users');
    print('Where: id = ${user.id}');
    print('Data: $updateData');

    final result = await db.update(
      'users',
      updateData,
      where: 'id = ?',
      whereArgs: [user.id],
    );

    print('Rows updated: $result');
    return result;
  }

  Future<User?> getUserById(int id) async {
    final db = await _databaseService.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }
}
