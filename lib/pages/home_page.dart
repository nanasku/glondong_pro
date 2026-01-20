import 'package:flutter/material.dart';
import 'package:tpk_app/widgets/sidebar.dart';
import 'package:tpk_app/pages/dashboard_page.dart';
import 'package:tpk_app/pages/profil.dart';
import 'package:tpk_app/pages/master_beli.dart';
import 'package:tpk_app/pages/master_jual.dart';
import 'package:tpk_app/pages/pembeli.dart';
import 'package:tpk_app/pages/penjual.dart';
import 'package:tpk_app/pages/transaksi_pembelian.dart';
import 'package:tpk_app/pages/transaksi_penjualan.dart';
import 'package:tpk_app/pages/laporan_pembelian.dart';
import 'package:tpk_app/pages/laporan_penjualan.dart';
import 'package:tpk_app/pages/laporan_labarugi.dart';
import 'package:tpk_app/pages/laporan_stok.dart';
import 'package:tpk_app/pages/operasional_tpk.dart';
import 'package:tpk_app/pages/backup_data.dart';
import 'package:tpk_app/pages/pengaturan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<SidebarState> _sidebarKey = GlobalKey<SidebarState>();

  void _onItemSelected(int index) {
    print('🔄 Menu diklik: index $index');

    switch (index) {
      case 1:
        _navigateToPage(const TransaksiPenjualan());
        return;
      case 2:
        _navigateToPage(const TransaksiPembelian());
        return;
      case 3:
        _navigateToPage(const MasterBeliPage());
        return;
      case 4:
        _navigateToPage(const MasterJualPage());
        return;
      case 5:
        _navigateToPage(const PembeliPage());
        return;
      case 6:
        _navigateToPage(const PenjualPage());
        return;
      case 7:
        _navigateToPage(const LaporanPembelianPage());
        return;
      case 8:
        _navigateToPage(const LaporanPenjualanPage());
        return;
      case 9:
        _navigateToPage(LaporanLabaRugiPage());
      case 10:
        _navigateToPage(const LaporanStokPage());
        return;
      case 11:
        _navigateToPage(
          ProfilPage(
            onProfileUpdated: () {
              setState(() {});
            },
          ),
        );
        return;
      case 12:
        _navigateToPage(const BackupDataPage());
      case 13:
        _navigateToPage(OperasionalTPKPage());
      case 14:
        _navigateToPage(PengaturanPage());
      default:
        setState(() {
          _selectedIndex = index;
        });
        break;
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page)).then(
      (_) {
        setState(() {
          _selectedIndex = 0;
        });
      },
    );
  }

  void _goToDashboard() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  Widget _getCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(
          onMenuSelected: _onItemSelected,
          onNavigateToPage: _navigateToPage,
        );
      case 1:
        return const TransaksiPenjualan();
      case 2:
        return const TransaksiPembelian();
      case 3:
        return const MasterBeliPage();
      case 4:
        return const MasterJualPage();
      case 5:
        return const PembeliPage();
      case 6:
        return const PenjualPage();
      case 7:
        return const LaporanPembelianPage();
      case 8:
        return const LaporanPenjualanPage();
      case 9:
        return LaporanLabaRugiPage();
      case 10:
        return const LaporanStokPage();
      case 11:
        return _buildPlaceholder('Profil Pengguna');
      case 12:
        return const BackupDataPage();
      case 13:
        return const OperasionalTPKPage();
      case 14:
        return const PengaturanPage();
      default:
        return DashboardPage(
          onMenuSelected: _onItemSelected,
          onNavigateToPage: _navigateToPage,
        );
    }
  }

  Widget _buildPlaceholder(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 40.0, color: Colors.grey[400]),
            const SizedBox(height: 12.0),
            Text(
              '$title\n(Sedang dalam pengembangan)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: _goToDashboard,
              icon: const Icon(Icons.home, size: 16.0),
              label: const Text('Kembali ke Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transaksi Penjualan';
      case 2:
        return 'Transaksi Pembelian';
      case 3:
        return 'Data Harga Beli';
      case 4:
        return 'Data Harga Jual';
      case 5:
        return 'Data Pembeli';
      case 6:
        return 'Data Penjual';
      case 7:
        return 'Laporan Pembelian';
      case 8:
        return 'Laporan Penjualan';
      case 9:
        return 'Laporan Laba Rugi';
      case 10:
        return 'Laporan Stok';
      case 11:
        return 'Profil Pengguna';
      case 12:
        return 'Backup Data';
      case 13:
        return 'Biaya Operasional TPK';
      case 14:
        return 'Pengaturan';
      default:
        return 'Glondong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: const TextStyle(fontSize: 16.0)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_selectedIndex != 0)
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: _goToDashboard,
              tooltip: 'Kembali ke Dashboard',
            ),
        ],
      ),
      drawer: Sidebar(
        onItemSelected: _onItemSelected,
        selectedIndex: _selectedIndex,
      ),
      body: _getCurrentPage(),
    );
  }
}
