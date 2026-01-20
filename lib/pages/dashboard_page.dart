import 'package:flutter/material.dart';
import 'package:tpk_app/pages/master_beli.dart';
import 'package:tpk_app/pages/profil.dart';
import 'package:tpk_app/services/database_service.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onMenuSelected;
  final Function(Widget) onNavigateToPage;

  const DashboardPage({
    super.key,
    required this.onMenuSelected,
    required this.onNavigateToPage,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseService _dbService = DatabaseService();

  int _jumlahPembelianHariIni = 0; // Jumlah transaksi pembelian
  int _jumlahPenjualanHariIni = 0; // Jumlah transaksi penjualan
  int _totalBatang = 0; // Total jumlah batang
  double _totalVolumeCm3 = 0.0; // Total volume dalam cm³ (sama dengan laporan)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistik();
  }

  Future<void> _loadStatistik() async {
    try {
      print('=== LOADING STATISTIK ===');

      // Menggunakan method yang sudah ada di DatabaseService
      final jumlahPembelian = await _dbService.getPembelianHariIni();
      print('Jumlah Pembelian (transaksi): $jumlahPembelian');

      final jumlahPenjualan = await _dbService.getPenjualanHariIni();
      print('Jumlah Penjualan (transaksi): $jumlahPenjualan');

      final totalBatang = await _dbService.getTotalBatang();
      print('Total Batang: $totalBatang');

      // Gunakan method baru yang sama dengan laporan
      final totalVolumeCm3 = await _dbService.getTotalVolumeCm3();
      print('Total Volume (cm³): $totalVolumeCm3 cm³');

      // Juga hitung dalam m³ untuk referensi
      final totalVolumeM3 = totalVolumeCm3 / 1000000;
      print('Total Volume (m³): ${totalVolumeM3.toStringAsFixed(6)} m³');

      setState(() {
        _jumlahPembelianHariIni = jumlahPembelian;
        _jumlahPenjualanHariIni = jumlahPenjualan;
        _totalBatang = totalBatang;
        _totalVolumeCm3 = totalVolumeCm3;
        _isLoading = false;
      });

      print('=== STATISTIK LOADED ===');
    } catch (e, stackTrace) {
      print('=== ERROR LOADING STATISTIK ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          const Text(
            'Selamat Datang di GLONDONG App',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16.0),

          // STATS SECTION
          _buildStatsSection(),
          const SizedBox(height: 20.0),

          // MENU TITLE
          const Text(
            'Menu Cepat',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12.0),

          // MENU GRID - Expanded agar memenuhi sisa space
          Expanded(child: _buildMenuGrid()),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistik Hari Ini',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: _loadStatistik,
                tooltip: 'Refresh Statistik',
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Pembelian',
                _jumlahPembelianHariIni.toString(),
                'Transaksi',
                Colors.blue,
                Icons.shopping_cart,
              ),
              _buildStatItem(
                'Penjualan',
                _jumlahPenjualanHariIni.toString(),
                'Transaksi',
                Colors.green,
                Icons.sell,
              ),
              _buildStatItem(
                'Stok Batang',
                _totalBatang.toString(),
                'Batang',
                Colors.orange,
                Icons.format_list_numbered,
              ),
              _buildStatItem(
                'Stok Volume',
                _formatVolume(_totalVolumeCm3),
                'cm³',
                Colors.purple,
                Icons.calculate,
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          // Info rumus
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          //   decoration: BoxDecoration(
          //     color: Colors.blue[50],
          //     borderRadius: BorderRadius.circular(4.0),
          //   ),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Icon(Icons.info, size: 10, color: Colors.blue[700]),
          //       const SizedBox(width: 4),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Helper method untuk format volume
  String _formatVolume(double volumeCm3) {
    if (volumeCm3 < 1000) {
      return '${volumeCm3.toStringAsFixed(0)}'; // cm³
    } else if (volumeCm3 < 1000000) {
      return '${(volumeCm3 / 1000).toStringAsFixed(1)}K'; // ribu cm³
    } else {
      return '${(volumeCm3 / 1000000).toStringAsFixed(2)}M'; // juta cm³
    }
  }

  Widget _buildStatItem(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(unit, style: TextStyle(fontSize: 8.0, color: color)),
                    ],
                  ),
          ),
          const SizedBox(height: 6.0),
          Text(
            title,
            style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10.0,
      mainAxisSpacing: 10.0,
      childAspectRatio: 1.0,
      padding: const EdgeInsets.all(0),
      children: [
        _buildDashboardCard(
          'Transaksi\nPembelian',
          Icons.shopping_cart,
          Colors.blue,
          () => widget.onMenuSelected(2),
        ),
        _buildDashboardCard(
          'Transaksi\nPenjualan',
          Icons.sell,
          Colors.green,
          () => widget.onMenuSelected(1),
        ),
        _buildDashboardCard(
          'Data Harga\nBeli',
          Icons.attach_money,
          Colors.red,
          () => widget.onNavigateToPage(const MasterBeliPage()),
        ),
        _buildDashboardCard(
          'Profil',
          Icons.settings,
          Colors.teal,
          () => widget.onNavigateToPage(ProfilPage(onProfileUpdated: () {})),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24.0, color: color),
              const SizedBox(height: 6.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
