// lib/widgets/activation_dialog.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tpk_app/services/activation_service.dart';

class ActivationDialog extends StatefulWidget {
  final Function(bool) onActivationComplete;

  const ActivationDialog({super.key, required this.onActivationComplete});

  @override
  State<ActivationDialog> createState() => _ActivationDialogState();
}

class _ActivationDialogState extends State<ActivationDialog> {
  final ActivationService _activationService = ActivationService();
  final TextEditingController _activationCodeController =
      TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();

  String _deviceSerial = 'Sedang mengambil...';
  String _generatedCode = '';
  bool _isLoading = true;
  bool _showGeneratedCode = false;
  bool _deviceInfoLoaded = false;
  Map<String, dynamic> _deviceInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadSavedData();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      // 1. Get device serial (STATIC - tidak bisa digenerate ulang)
      final serial = await _activationService.getDeviceSerial();

      // 2. Get device info untuk display
      final info = await _activationService.getDeviceInfo();

      if (mounted) {
        setState(() {
          _deviceSerial = serial;
          _deviceInfo = info;
          _deviceInfoLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceSerial = 'Error: Tidak bisa mendapatkan Serial Number';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSavedData() async {
    // Load owner name jika sudah ada
    String? savedOwnerName = await _activationService.getOwnerName();
    if (savedOwnerName != null && savedOwnerName.isNotEmpty) {
      if (mounted) {
        setState(() {
          _ownerNameController.text = savedOwnerName;
        });
      }
    }
  }

  Future<void> _previewActivationCode() async {
    if (_ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama pemilik perusahaan')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String activationCode = _activationService.generateActivationCode(
        _deviceSerial,
        _ownerNameController.text,
      );

      if (mounted) {
        setState(() {
          _generatedCode = activationCode;
          _showGeneratedCode = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _activateApp() async {
    // Validasi input
    if (_ownerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama pemilik perusahaan')),
      );
      return;
    }

    final inputCode = _activationCodeController.text.trim();
    if (inputCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Masukkan kode aktivasi')));
      return;
    }

    // Validasi format kode
    final cleanedCode = inputCode.replaceAll('-', '').toUpperCase();
    if (cleanedCode.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode aktivasi harus 16 karakter')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Verifikasi kode
    bool isValid = _activationService.verifyActivationCode(
      _deviceSerial,
      _ownerNameController.text,
      inputCode,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (isValid) {
      // Simpan semua data
      await _activationService.setActivated(true);
      await _activationService.saveActivationCode(inputCode);
      await _activationService.saveOwnerName(_ownerNameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Aktivasi berhasil!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 1));

      widget.onActivationComplete(true);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        // Tampilkan kode yang diharapkan untuk bantuan
        final expectedCode = _activationService.generateActivationCode(
          _deviceSerial,
          _ownerNameController.text,
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kode Tidak Valid'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kode aktivasi yang dimasukkan tidak valid.'),
                const SizedBox(height: 15),
                const Text(
                  'Pastikan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text('1. Serial number sudah benar'),
                const Text('2. Nama sudah benar'),
                const Text('3. Kode aktivasi sesuai'),
                const SizedBox(height: 10),
                if (expectedCode.isNotEmpty) ...[
                  const Text('Ajukan aktivasi ke:'),
                  const Text('abuizdiharnurokhman@gmail.com'),
                  const SizedBox(height: 5),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Serial number disalin'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showDeviceInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Perangkat'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Serial Number:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              SelectableText(
                _deviceSerial,
                style: const TextStyle(fontFamily: 'RobotoMono'),
              ),
              const SizedBox(height: 15),
              const Text(
                'Detail Perangkat:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              ..._deviceInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value?.toString() ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 15),
              const Text(
                'Catatan:',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const Text(
                '• Serial number ini unik untuk perangkat Anda',
                style: TextStyle(fontSize: 11),
              ),
              const Text(
                '• Serial number tidak dapat diubah',
                style: TextStyle(fontSize: 11),
              ),
              const Text(
                '• Kirim Serial number ini ke admin untuk aktivasi',
                style: TextStyle(fontSize: 11),
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
              _copyToClipboard(_deviceSerial);
              Navigator.pop(context);
            },
            child: const Text('Salin Serial'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 5,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Aktivasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 16),

                // Section 1: Device Serial (STATIC)
                const Text(
                  '1. Serial Number',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _deviceInfoLoaded ? Icons.check_circle : Icons.sync,
                            color: _deviceInfoLoaded
                                ? Colors.green
                                : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _isLoading
                                ? const Text(
                                    'Mengambil Serial Number...',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : SelectableText(
                                    _deviceSerial,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'RobotoMono',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                          if (_deviceInfoLoaded)
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () => _copyToClipboard(_deviceSerial),
                              tooltip: 'Salin Serial Number',
                              color: Colors.blue,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: Nama Pemilik Perusahaan
                const Text(
                  '2. Nama',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Minimal 3 karakter',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _ownerNameController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: SANTOSO',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 50,
                  onChanged: (value) {
                    setState(() {
                      _showGeneratedCode = false; // Reset saat nama berubah
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Section 3: Kode Aktivasi
                const Text(
                  '3. Kode Aktivasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan kode yang diberikan',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _activationCodeController,
                  decoration: InputDecoration(
                    hintText: 'Format: XXXX-XXXX-XXXX-XXXX',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key, color: Colors.green),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'RobotoMono',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    // Auto-format dengan dash
                    String cleaned = value.replaceAll('-', '').toUpperCase();
                    if (cleaned.length > 16) {
                      cleaned = cleaned.substring(0, 16);
                    }

                    String formatted = '';
                    for (int i = 0; i < cleaned.length; i++) {
                      if (i > 0 && i % 4 == 0) {
                        formatted += '-';
                      }
                      formatted += cleaned[i];
                    }

                    if (formatted != value) {
                      _activationCodeController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_deviceInfoLoaded)
                            ? null
                            : _activateApp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Aktivasi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Catatan Pengguna',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lisensi aplikasi Glondong App hanya berlaku untuk satu perangkat.'
                        'Jika mengganti perangkat atau mengganti hardware pada perangkat, perlu aktivasi baru.',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activationCodeController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }
}
