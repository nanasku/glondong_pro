import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tpk_app/services/database_service.dart';
import 'package:tpk_app/pages/home_page.dart';
import 'package:sqflite/sqflite.dart';

class BackupDataPage extends StatefulWidget {
  const BackupDataPage({super.key});

  @override
  State<BackupDataPage> createState() => _BackupDataPageState();
}

class _BackupDataPageState extends State<BackupDataPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String _backupStatus = '';
  String _restoreStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore Data'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildBackupSection(),
            const SizedBox(height: 20),
            _buildRestoreSection(),
            const SizedBox(height: 20),
            _buildResetSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Informasi Backup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Backup akan menyimpan database ke direktori Documents',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '• Restore akan mengembalikan data dari file backup terbaru',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '• File backup disimpan dengan format: tpk_backup_YYYYMMDD_HHMM.db',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup Data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Simpan semua data transaksi, master, dan laporan ke file backup.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            if (_backupStatus.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backupStatus.contains('Berhasil')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _backupStatus.contains('Berhasil')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _backupStatus.contains('Berhasil')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _backupStatus.contains('Berhasil')
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _backupStatus,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: _isBackingUp ? null : _backupDatabase,
              icon: _isBackingUp
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.backup, size: 20),
              label: Text(_isBackingUp ? 'Sedang Backup...' : 'Backup Data'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restore Data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Kembalikan data dari file backup sebelumnya.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            if (_restoreStatus.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _restoreStatus.contains('Berhasil')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _restoreStatus.contains('Berhasil')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _restoreStatus.contains('Berhasil')
                          ? Icons.check_circle
                          : Icons.error,
                      color: _restoreStatus.contains('Berhasil')
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _restoreStatus,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: _isRestoring ? null : _restoreDatabase,
              icon: _isRestoring
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.restore, size: 20),
              label: Text(_isRestoring ? 'Sedang Restore...' : 'Restore Data'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSection() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Reset Database',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Hapus semua data dan reset ke kondisi awal. Tindakan ini tidak dapat dibatalkan!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _showResetConfirmation,
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text('Reset Database'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupDatabase() async {
    setState(() {
      _isBackingUp = true;
      _backupStatus = '';
    });

    try {
      // Dapatkan path database asli
      final databasesPath = await getDatabasesPath();
      final sourcePath = '$databasesPath/tpk.db';

      // Cek apakah file database ada
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        setState(() {
          _backupStatus = 'File database tidak ditemukan';
        });
        return;
      }

      // Gunakan getApplicationDocumentsDirectory untuk Android/iOS compatibility
      final Directory? externalDir = await getExternalStorageDirectory();
      final backupDir = Directory('${externalDir?.path}/TPK_Backup');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Buat nama file backup dengan timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final backupPath = '${backupDir.path}/tpk_backup_$timestamp.db';

      // Copy file database ke lokasi backup
      await sourceFile.copy(backupPath);

      setState(() {
        _backupStatus = 'Backup berhasil! File disimpan di: ${backupDir.path}';
      });

      _showSuccessDialog(
        'Backup Berhasil',
        'Data berhasil dibackup.\n\nFile: tpk_backup_$timestamp.db',
      );
    } catch (e) {
      setState(() {
        _backupStatus = 'Error saat backup: $e';
      });
    } finally {
      setState(() {
        _isBackingUp = false;
      });
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() {
      _isRestoring = true;
      _restoreStatus = '';
    });

    try {
      // Gunakan getApplicationDocumentsDirectory
      final Directory? externalDir = await getExternalStorageDirectory();
      final backupDir = Directory('${externalDir?.path}/TPK_Backup');

      if (!await backupDir.exists()) {
        setState(() {
          _restoreStatus = 'Direktori backup tidak ditemukan';
        });
        return;
      }

      // List semua file backup
      final List<FileSystemEntity> backupFiles = await backupDir
          .list()
          .toList();
      final List<File> dbFiles = backupFiles
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      if (dbFiles.isEmpty) {
        setState(() {
          _restoreStatus = 'Tidak ada file backup ditemukan';
        });
        return;
      }

      // Urutkan file berdasarkan tanggal modifikasi (terbaru pertama)
      dbFiles.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final File latestBackup = dbFiles.first;

      // Tutup koneksi database yang sedang aktif
      await _databaseService.close();

      // Dapatkan path database asli
      final databasesPath = await getDatabasesPath();
      final targetPath = '$databasesPath/tpk.db';

      // Hapus database yang lama
      final File targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // Copy file backup ke lokasi database
      await latestBackup.copy(targetPath);

      // Re-initialize database
      await _databaseService.initializeDatabase();

      setState(() {
        _restoreStatus = 'Restore berhasil! Data telah dikembalikan.';
      });

      _showSuccessDialog(
        'Restore Berhasil',
        'Data berhasil direstore dari backup terbaru.',
      );
    } catch (e) {
      setState(() {
        _restoreStatus = 'Error saat restore: $e';
      });
    } finally {
      setState(() {
        _isRestoring = false;
      });
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Konfirmasi Reset'),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin mereset database? '
            'Semua data transaksi, master, dan laporan akan dihapus permanen. '
            'Tindakan ini tidak dapat dibatalkan!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetDatabase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetDatabase() async {
    try {
      await DatabaseService.resetDatabase();

      _showSuccessDialog(
        'Reset Berhasil',
        'Database telah direset ke kondisi awal. '
            'Aplikasi akan restart otomatis.',
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat reset database: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
