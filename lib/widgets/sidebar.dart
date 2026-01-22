import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class Sidebar extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const Sidebar({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  late Future<User?> _userFuture;
  final UserService _userService = UserService();
  BuildContext? _menuContext;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    if (mounted) {
      setState(() {
        _userFuture = _userService.getCurrentUser();
      });
    }
  }

  // ✅ METHOD UNTUK REFRESH PROFIL
  void refreshProfile() {
    if (mounted) {
      setState(() {
        // Force refresh dengan membuat future baru
        _userFuture = _userService.getCurrentUser().then((user) {
          print('Sidebar refreshProfile: User loaded - ${user?.email}');
          return user;
        });
      });
    }
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.blue[700]),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PROFILE PHOTO
            Stack(
              children: [
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  child:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.file(
                            File(user.profileImage!),
                            fit: BoxFit.cover,
                            width: 60.0,
                            height: 60.0,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30.0,
                                color: Colors.blue[700],
                              );
                            },
                          ),
                        )
                      : Icon(Icons.person, size: 30.0, color: Colors.blue[700]),
                ),
                // ONLINE INDICATOR
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // COMPANY NAME
            Text(
              user.companyName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),

            // USERNAME
            Text(
              '@${user.username}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2.0),

            // EMAIL
            Text(
              user.email,
              style: TextStyle(color: Colors.white70, fontSize: 10.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ALAMAT (jika ada)
            if (user.alamat != null && user.alamat!.isNotEmpty) ...[
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Icon(Icons.location_on, size: 10.0, color: Colors.white70),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Text(
                      user.alamat!,
                      style: TextStyle(color: Colors.white70, fontSize: 9.0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.blue[700]),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOADING PROFILE PHOTO
            Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),

            // LOADING TEXTS
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8.0),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4.0),
            Container(
              width: 150,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.blue[700]),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ERROR PROFILE PHOTO
            Container(
              width: 60.0,
              height: 60.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
              child: Icon(Icons.error_outline, color: Colors.white, size: 24.0),
            ),
            const SizedBox(height: 12.0),

            // ERROR MESSAGE
            Text(
              'Glondong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Gagal memuat profil',
              style: TextStyle(color: Colors.white70, fontSize: 12.0),
            ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onTap: _loadUserProfile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tap untuk refresh',
                  style: TextStyle(color: Colors.white, fontSize: 9.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(int index) {
    // Tutup drawer terlebih dahulu
    if (_menuContext != null) {
      Navigator.pop(_menuContext!);
    }

    // Panggil callback setelah delay kecil
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onItemSelected(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // HEADER SECTION DENGAN DATA PROFIL
          FutureBuilder<User?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingHeader();
              } else if (snapshot.hasError) {
                return _buildErrorHeader();
              } else if (!snapshot.hasData || snapshot.data == null) {
                return _buildErrorHeader();
              }

              final user = snapshot.data!;
              return _buildProfileHeader(user);
            },
          ),

          // MENU LIST - STRUKTUR YANG LEBIH SEDERHANA
          Expanded(
            child: Builder(
              builder: (menuContext) {
                // Simpan context untuk digunakan nanti
                _menuContext = menuContext;

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuTile(
                      index: 0,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      isSelected: widget.selectedIndex == 0,
                    ),
                    _buildSectionHeader('TRANSAKSI'),
                    _buildMenuTile(
                      index: 15,
                      icon: Icons.sell,
                      title: 'Transaksi Oper Nota',
                      isSelected: widget.selectedIndex == 15,
                    ),
                    _buildMenuTile(
                      index: 1,
                      icon: Icons.sell,
                      title: 'Transaksi Penjualan',
                      isSelected: widget.selectedIndex == 1,
                    ),
                    _buildMenuTile(
                      index: 2,
                      icon: Icons.shopping_cart,
                      title: 'Transaksi Pembelian',
                      isSelected: widget.selectedIndex == 2,
                    ),
                    _buildMenuTile(
                      index: 13,
                      icon: Icons.business_center,
                      title: 'Biaya Operasional TPK',
                      isSelected: widget.selectedIndex == 13,
                    ),
                    _buildSectionHeader('DATA MASTER'),
                    _buildMenuTile(
                      index: 3,
                      icon: Icons.attach_money,
                      title: 'Data Harga Beli',
                      isSelected: widget.selectedIndex == 3,
                    ),
                    _buildMenuTile(
                      index: 4,
                      icon: Icons.monetization_on,
                      title: 'Data Harga Jual',
                      isSelected: widget.selectedIndex == 4,
                    ),
                    _buildMenuTile(
                      index: 5,
                      icon: Icons.people,
                      title: 'Data Pembeli',
                      isSelected: widget.selectedIndex == 5,
                    ),
                    _buildMenuTile(
                      index: 6,
                      icon: Icons.person,
                      title: 'Data Penjual',
                      isSelected: widget.selectedIndex == 6,
                    ),
                    _buildSectionHeader('LAPORAN'),
                    _buildMenuTile(
                      index: 7,
                      icon: Icons.receipt,
                      title: 'Laporan Pembelian',
                      isSelected: widget.selectedIndex == 7,
                    ),
                    _buildMenuTile(
                      index: 8,
                      icon: Icons.receipt_long,
                      title: 'Laporan Penjualan',
                      isSelected: widget.selectedIndex == 8,
                    ),
                    _buildMenuTile(
                      index: 9,
                      icon: Icons.trending_up,
                      title: 'Laporan Laba Rugi',
                      isSelected: widget.selectedIndex == 9,
                    ),
                    _buildMenuTile(
                      index: 10,
                      icon: Icons.inventory,
                      title: 'Laporan Stok',
                      isSelected: widget.selectedIndex == 10,
                    ),
                    _buildSectionHeader('LAINNYA'),
                    _buildMenuTile(
                      index: 11,
                      icon: Icons.person,
                      title: 'Profil Pengguna',
                      isSelected: widget.selectedIndex == 11,
                    ),
                    _buildMenuTile(
                      index: 12,
                      icon: Icons.backup,
                      title: 'Backup Data',
                      isSelected: widget.selectedIndex == 12,
                    ),
                    _buildMenuTile(
                      index: 14, // Index baru untuk Pengaturan
                      icon: Icons.settings,
                      title: 'Pengaturan',
                      isSelected: widget.selectedIndex == 14,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 18.0,
        color: isSelected ? Colors.blue : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () => _handleMenuTap(index),
    );
  }
}
