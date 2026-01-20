import 'database_service.dart';
import 'package:tpk_app/models/user_model.dart';
import 'package:tpk_app/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHKAN

class UserService {
  final UserRepository _userRepository = UserRepository();

  Future<User?> login(String email, String password) async {
    final user = await _userRepository.getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  Future<bool> updateProfile(User user) async {
    try {
      await _userRepository.updateUser(user);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // Cek email dari SharedPreferences dulu
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('current_user_email');

      print('UserService: Saved email from prefs: $savedEmail');

      User? user;

      // Cari user berdasarkan email dari preferences
      if (savedEmail != null && savedEmail.isNotEmpty) {
        user = await _userRepository.getUserByEmail(savedEmail);
        if (user != null) {
          print('UserService: User found with prefs email: ${user.email}');
          return user;
        }
      }

      // Jika tidak ditemukan, coba dengan email default
      print('UserService: Trying default email: admin@tpk.com');
      user = await _userRepository.getUserByEmail('admin@tpk.com');

      if (user != null) {
        print('UserService: User found with default email: ${user.email}');
        // Simpan email default ke preferences untuk konsistensi
        await prefs.setString('current_user_email', user.email);
        return user;
      }

      // Jika masih tidak ditemukan, ambil user pertama dari database
      print('UserService: Getting first user from database');
      final dbService = DatabaseService();
      final db = await dbService.database;
      final users = await db.query('users', limit: 1);

      if (users.isNotEmpty) {
        user = User.fromMap(users.first);
        print('UserService: First user found: ${user.email}');
        // Simpan email ke preferences
        await prefs.setString('current_user_email', user.email);
        return user;
      }

      print('UserService: No user found at all');
      return null;
    } catch (e) {
      print('UserService Error: $e');
      return null;
    }
  }

  // Method untuk mendapatkan user by email (tambahkan jika belum ada)
  Future<User?> getUserByEmail(String email) async {
    try {
      return await _userRepository.getUserByEmail(email);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(User user) async {
    try {
      await _userRepository.updateUser(user);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Method untuk update company profile
  Future<bool> updateCompanyProfile({
    required String companyName,
    required String alamat,
    String? profileImage,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = User(
          id: currentUser.id,
          username: currentUser.username,
          email: currentUser.email,
          password: currentUser.password,
          companyName: companyName,
          alamat: alamat,
          profileImage: profileImage ?? currentUser.profileImage,
          createdAt: currentUser.createdAt,
          updatedAt: DateTime.now().toString(),
        );
        return await updateProfile(updatedUser);
      }
      return false;
    } catch (e) {
      print('Error updating company profile: $e');
      return false;
    }
  }
}
