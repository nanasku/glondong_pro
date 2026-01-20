import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // TAMBAHKAN
import 'dart:io';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/database_service.dart'; // TAMBAHKAN INI

class ProfilPage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfilPage({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  _ProfilPageState createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late Future<User?> _userFuture;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    setState(() {
      _userFuture = _getUserProfile();
    });
  }

  Future<User?> _getUserProfile() async {
    try {
      final userService = UserService();
      User? user;

      // PERBAIKAN: Gunakan SharedPreferences langsung atau perbaiki PreferencesService
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('current_user_email');
      print('Saved email from prefs: $savedEmail');

      if (savedEmail != null && savedEmail.isNotEmpty) {
        // PERBAIKAN: UserService tidak punya method getUserByEmail, gunakan UserRepository
        // Atau tambahkan method ke UserService
        final dbService = DatabaseService();
        final db = await dbService.database;
        final users = await db.query(
          'users',
          where: 'email = ?',
          whereArgs: [savedEmail],
        );
        if (users.isNotEmpty) {
          user = User.fromMap(users.first);
        }
      }

      // Jika tidak ditemukan dengan email dari prefs, coba dengan default
      if (user == null) {
        print('User not found with email from prefs, trying default...');
        final dbService = DatabaseService();
        final db = await dbService.database;
        final users = await db.query(
          'users',
          where: 'email = ?',
          whereArgs: ['admin@tpk.com'],
        );
        if (users.isNotEmpty) {
          user = User.fromMap(users.first);
        }
      }

      // Jika masih tidak ditemukan, ambil user pertama dari database
      if (user == null) {
        print('Trying to get first user from database...');
        final dbService = DatabaseService();
        final db = await dbService.database;
        final users = await db.query('users', limit: 1);
        if (users.isNotEmpty) {
          user = User.fromMap(users.first);
        }
      }

      if (user != null) {
        print('User found: ${user.email}, ${user.username}');
      } else {
        print('No user found at all');
      }

      return user;
    } catch (e) {
      print('Error loading user: $e');
      return null;
    }
  }

  Future<File?> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      _showError('Gagal memilih gambar: $e');
    }
    return null;
  }

  Future<void> _updateProfile(User updatedUser, File? imageFile) async {
    try {
      print('=== UPDATE PROFILE PROCESS START ===');

      // Validation
      if (updatedUser.email.isEmpty) {
        _showError('Email tidak boleh kosong');
        return;
      }

      if (!updatedUser.email.contains('@')) {
        _showError('Format email tidak valid');
        return;
      }

      String? newProfileImage;
      if (imageFile != null) {
        newProfileImage = imageFile.path;
      }

      final updatedUserWithImage = User(
        id: updatedUser.id,
        username: updatedUser.username,
        email: updatedUser.email,
        password: updatedUser.password,
        companyName: updatedUser.companyName,
        alamat: updatedUser.alamat,
        profileImage: newProfileImage ?? updatedUser.profileImage,
        createdAt: updatedUser.createdAt,
        updatedAt: DateTime.now().toString(),
      );

      print('Updating user with new email: ${updatedUserWithImage.email}');

      final userService = UserService();
      final success = await userService.updateProfile(updatedUserWithImage);

      if (success) {
        print('Update profile SUCCESS');

        // Simpan email baru ke preferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'current_user_email',
            updatedUserWithImage.email,
          );
          print('Saved new email to prefs: ${updatedUserWithImage.email}');

          // Debug: cek semua data di database
          final dbService = DatabaseService();
          final db = await dbService.database;
          final allUsers = await db.query('users');
          print('=== ALL USERS IN DATABASE ===');
          for (var user in allUsers) {
            print(
              'ID: ${user['id']}, Email: ${user['email']}, Username: ${user['username']}',
            );
          }
        } catch (e) {
          print('Error saving to prefs: $e');
        }

        _showSuccess('Profil berhasil diperbarui');

        // Refresh data
        await Future.delayed(Duration(milliseconds: 300));
        _loadUserProfile();

        setState(() {
          _selectedImage = null;
        });

        // Notify parent untuk refresh sidebar
        if (widget.onProfileUpdated != null) {
          print('Calling onProfileUpdated callback');
          widget.onProfileUpdated!();
        } else {
          print('onProfileUpdated callback is null');
        }

        // Force rebuild
        if (mounted) {
          setState(() {});
        }
      } else {
        print('Update profile FAILED (returned false)');
        _showError('Gagal memperbarui profil. Silakan coba lagi.');
      }
    } catch (e, stackTrace) {
      print('=== UPDATE PROFILE ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      String errorMessage = 'Terjadi kesalahan saat menyimpan';

      if (e.toString().contains('UNIQUE constraint failed')) {
        errorMessage = 'Email sudah digunakan. Gunakan email lain.';
      } else if (e.toString().contains('NOT NULL constraint failed')) {
        errorMessage =
            'Data tidak lengkap. Harap isi semua field yang diperlukan.';
      } else if (e.toString().contains('SQLite')) {
        errorMessage = 'Database error. Coba restart aplikasi.';
      }

      _showError('$errorMessage\n\n${e.toString().split('\n').first}');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditDialog(User user) {
    TextEditingController usernameController = TextEditingController(
      text: user.username,
    );
    TextEditingController emailController = TextEditingController(
      text: user.email,
    );
    TextEditingController companyController = TextEditingController(
      text: user.companyName,
    );
    TextEditingController alamatController = TextEditingController(
      text: user.alamat ?? '',
    );

    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profil', style: TextStyle(fontSize: 16.0)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final File? imageFile = await _pickImage();
                    if (imageFile != null) {
                      setDialogState(() {
                        selectedImage = imageFile;
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : (user.profileImage != null &&
                                  user.profileImage!.isNotEmpty
                              ? FileImage(File(user.profileImage!))
                              : null),
                    child:
                        selectedImage == null &&
                            (user.profileImage == null ||
                                user.profileImage!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 30.0,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Tap foto untuk mengubah',
                  style: TextStyle(fontSize: 10.0, color: Colors.grey),
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'Gambar baru dipilih',
                    style: TextStyle(fontSize: 10.0, color: Colors.green[700]),
                  ),
                ],
                const SizedBox(height: 16.0),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perusahaan *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: alamatController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '* Field wajib diisi',
                  style: TextStyle(fontSize: 10.0, color: Colors.red[700]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi input
                if (usernameController.text.isEmpty) {
                  _showError('Username harus diisi');
                  return;
                }
                if (emailController.text.isEmpty) {
                  _showError('Email harus diisi');
                  return;
                }
                if (!emailController.text.contains('@')) {
                  _showError('Format email tidak valid');
                  return;
                }
                if (companyController.text.isEmpty) {
                  _showError('Nama Perusahaan harus diisi');
                  return;
                }

                final updatedUser = User(
                  id: user.id,
                  username: usernameController.text.trim(),
                  email: emailController.text.trim(),
                  password: user.password,
                  companyName: companyController.text.trim(),
                  alamat: alamatController.text.isEmpty
                      ? null
                      : alamatController.text.trim(),
                  profileImage: user.profileImage,
                  createdAt: user.createdAt,
                  updatedAt: user.updatedAt,
                );

                Navigator.pop(context);
                await _updateProfile(updatedUser, selectedImage);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(fontSize: 16.0)),
        content: const Text(
          'Apakah Anda yakin ingin logout?',
          style: TextStyle(fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showResetDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Database', style: TextStyle(fontSize: 16.0)),
        content: const Text(
          'PERINGATAN: Ini akan menghapus semua data dan membuat database baru. Hanya untuk development!',
          style: TextStyle(fontSize: 12.0, color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await DatabaseService.resetDatabase();
                _showSuccess('Database berhasil direset. Restart aplikasi.');
                _loadUserProfile();
              } catch (e) {
                _showError('Gagal reset database: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(fontSize: 16.0)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20.0),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _showResetDatabaseDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16.0, color: Colors.red),
                    SizedBox(width: 8.0),
                    Text('Reset Database'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<User?>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16.0),
                    Text(
                      'Memuat data profil...',
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40.0, color: Colors.red),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Gagal memuat profil',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: _showResetDatabaseDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Reset Database'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_off,
                      size: 40.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Data profil tidak ditemukan',
                      style: TextStyle(fontSize: 14.0),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Muat Ulang'),
                    ),
                  ],
                ),
              );
            }

            final user = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                          border: Border.all(color: Colors.blue, width: 2.0),
                        ),
                        child:
                            user.profileImage != null &&
                                user.profileImage!.isNotEmpty
                            ? ClipOval(
                                child: Image.file(
                                  File(user.profileImage!),
                                  fit: BoxFit.cover,
                                  width: 100.0,
                                  height: 100.0,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 40.0,
                                      color: Colors.grey[600],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 40.0,
                                color: Colors.grey[600],
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final image = await _pickImage();
                            if (image != null) {
                              await _updateProfile(user, image);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  Text(
                    user.companyName,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Username: ${user.username}',
                    style: TextStyle(fontSize: 11.0, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24.0),

                  _buildInfoCard('Username', user.username, Icons.person),
                  const SizedBox(height: 8.0),
                  _buildInfoCard(
                    'Nama Perusahaan',
                    user.companyName,
                    Icons.business,
                  ),
                  const SizedBox(height: 8.0),
                  _buildInfoCard('Email', user.email, Icons.email),
                  const SizedBox(height: 8.0),
                  _buildInfoCard(
                    'Alamat',
                    user.alamat ?? 'Belum diisi',
                    Icons.location_on,
                  ),

                  const SizedBox(height: 32.0),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showEditDialog(user),
                          icon: const Icon(Icons.edit, size: 16.0),
                          label: const Text('Edit Profil'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout, size: 16.0),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2.0,
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20.0, color: Colors.blue[700]),
        title: Text(title, style: const TextStyle(fontSize: 12.0)),
        subtitle: Text(value, style: const TextStyle(fontSize: 11.0)),
      ),
    );
  }
}
