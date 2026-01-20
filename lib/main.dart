// lib/main.dart (UPDATE LENGKAP)
import 'package:flutter/material.dart';
import 'package:tpk_app/pages/home_page.dart';
import 'package:tpk_app/services/preferences_service.dart';
import 'package:tpk_app/services/activation_service.dart';
import 'package:tpk_app/widgets/activation_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences sebelum runApp
  await PreferencesService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPK App',
      debugShowCheckedModeBanner: false,

      // ✅ THEME GLOBAL
      theme: ThemeData(
        useMaterial3: true,

        // COLOR SCHEME
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),

        // TYPOGRAPHY
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          displaySmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
          bodySmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),

        // BUTTON THEME
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // INPUT DECORATION
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),

      // HOME: Check activation status dengan load nama pemilik
      home: const ActivationCheckScreen(),
    );
  }
}

// Screen untuk check activation status
class ActivationCheckScreen extends StatefulWidget {
  const ActivationCheckScreen({super.key});

  @override
  State<ActivationCheckScreen> createState() => _ActivationCheckScreenState();
}

class _ActivationCheckScreenState extends State<ActivationCheckScreen> {
  final ActivationService _activationService = ActivationService();
  late Future<Map<String, dynamic>> _activationDataFuture;

  @override
  void initState() {
    super.initState();
    _activationDataFuture = _getActivationData();
  }

  // Helper method untuk mendapatkan data aktivasi
  Future<Map<String, dynamic>> _getActivationData() async {
    try {
      final isActivated = await _activationService.isActivated();
      final ownerName = await _activationService.getOwnerName();
      final deviceSerial = await _activationService.getDeviceSerial();
      final activationCode = await _activationService.getActivationCode();

      return {
        'isActivated': isActivated,
        'ownerName': ownerName,
        'deviceSerial': deviceSerial,
        'activationCode': activationCode,
        'hasError': false,
        'errorMessage': '',
      };
    } catch (e) {
      print('Error getting activation data: $e');
      return {
        'isActivated': false,
        'ownerName': null,
        'deviceSerial': null,
        'activationCode': null,
        'hasError': true,
        'errorMessage': e.toString(),
      };
    }
  }

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      _activationDataFuture = _getActivationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _activationDataFuture,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Error state
        if (snapshot.hasError || (snapshot.data?['hasError'] ?? false)) {
          return _buildErrorScreen(
            snapshot.error?.toString() ??
                snapshot.data?['errorMessage'] ??
                'Unknown error',
          );
        }

        final data = snapshot.data!;
        final bool isActivated = data['isActivated'] ?? false;
        final String? ownerName = data['ownerName'];

        // Jika belum diaktivasi, tampilkan screen aktivasi
        if (!isActivated) {
          return _buildActivationRequiredScreen(ownerName);
        }

        // Jika sudah diaktivasi, tampilkan home page
        return const HomePage();
      },
    );
  }

  // Loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              'Memeriksa Status Aktivasi...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Glondong Application',
              style: TextStyle(
                fontSize: 24,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error screen
  Widget _buildErrorScreen(String errorMessage) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade700),
              const SizedBox(height: 20),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage.length > 100
                    ? '${errorMessage.substring(0, 100)}...'
                    : errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _showActivationDialog(),
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: const Text('Aktivasi Manual'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Activation required screen
  Widget _buildActivationRequiredScreen(String? existingOwnerName) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.business,
                    size: 80,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 30),

                // Title
                const Text(
                  'SELAMAT DATANG DI TPK APP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Subtitle
                Text(
                  'Aplikasi Manajemen Tempat Penampungan Kayu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Informasi Aktivasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Aplikasi ini memerlukan aktivasi untuk dapat digunakan. '
                        'Proses aktivasi hanya dilakukan sekali.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (existingOwnerName != null &&
                          existingOwnerName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nama pemilik terdeteksi: $existingOwnerName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Activation button
                ElevatedButton.icon(
                  onPressed: () => _showActivationDialog(
                    existingOwnerName: existingOwnerName,
                  ),
                  icon: const Icon(Icons.lock_open, size: 22),
                  label: const Text(
                    'AKTIVASI APLIKASI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 55),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.blue.shade300,
                  ),
                ),

                const SizedBox(height: 15),

                // Demo/Info button
                OutlinedButton.icon(
                  onPressed: () {
                    _showDemoInfoDialog();
                  },
                  icon: const Icon(Icons.help, size: 18),
                  label: const Text('Cara Aktivasi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(200, 45),
                    side: BorderSide(color: Colors.blue.shade400),
                  ),
                ),

                const SizedBox(height: 40),

                // Footer
                Column(
                  children: [
                    Text(
                      '© ${DateTime.now().year} TPK App',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show activation dialog
  void _showActivationDialog({String? existingOwnerName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivationDialog(
        onActivationComplete: (success) {
          if (success) {
            // Refresh data setelah aktivasi berhasil
            _refreshData().then((_) {
              // Navigate to home page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            });
          }
        },
      ),
    );
  }

  // Show demo info dialog
  void _showDemoInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 10),
            Text('Panduan Aktivasi'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Langkah-langkah aktivasi:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInfoStep('1. Klik tombol "AKTIVASI APLIKASI"'),
              _buildInfoStep('2. Copy Serial Number'),
              _buildInfoStep(
                '3. Kirim Serial Number ke admin untuk mendapatkan kode aktivasi',
              ),
              _buildInfoStep('4. Isi nama'),
              _buildInfoStep('5. Masukkan kode aktivasi dari admin'),
              _buildInfoStep('6. Klik tombol "Aktivasi"'),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Info Penting:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '• Kode aktivasi berlaku untuk satu perangkat\n'
                      '• Aktivasi hanya dilakukan sekali',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showActivationDialog();
            },
            child: const Text('Mulai Aktivasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
