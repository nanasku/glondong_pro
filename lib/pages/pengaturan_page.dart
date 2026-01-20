import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tpk_app/services/preferences_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart'; // Tambahkan ini di bagian atas

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final PreferencesService _prefs = PreferencesService();
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _selectedDevice;
  String? _printerType;
  bool _isLoading = true;
  bool _autoPrint = false;
  bool _duplicatePrint = false;
  bool _isConnecting = false;
  bool _isConnected = false;

  // TextEditingController untuk custom text
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _alamatTokoController = TextEditingController();
  final TextEditingController _teleponTokoController = TextEditingController();
  final TextEditingController _ucapanTerimakasihController =
      TextEditingController();
  final TextEditingController _catatanKakiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _teleponTokoController.dispose();
    _ucapanTerimakasihController.dispose();
    _catatanKakiController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      // Load semua setting
      final autoPrintValue = await _prefs.getAutoPrint();
      final duplicatePrintValue = await _prefs.getDuplicatePrint();

      // Load setting custom text
      final namaToko = await _prefs.getNamaPerusahaan() ?? 'TOKO KAYU JAYA';
      final alamatToko = await _prefs.getAlamatPerusahaan() ?? '';
      final teleponToko = await _prefs.getTeleponPerusahaan() ?? '';
      final ucapanTerimakasih =
          await _prefs.getFooterText() ?? 'TERIMA KASIH TELAH BERBELANJA';
      final catatanKaki =
          await _prefs.getCatatanKaki() ??
          'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan';

      setState(() {
        _printerType = _prefs.getPrinterTypeSync() ?? '58mm';
        _autoPrint = autoPrintValue ?? false;
        _duplicatePrint = duplicatePrintValue ?? false;
        _isLoading = false;
      });

      // Set nilai default untuk controller
      _namaTokoController.text = namaToko;
      _alamatTokoController.text = alamatToko;
      _teleponTokoController.text = teleponToko;
      _ucapanTerimakasihController.text = ucapanTerimakasih;
      _catatanKakiController.text = catatanKaki;

      // Load printer yang sudah disimpan
      await _loadSavedPrinter();

      // Scan printer Bluetooth
      await _scanBluetoothPrinters();
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedPrinter() async {
    try {
      final savedDeviceName = _prefs.getPrinterNameSync();
      final savedDeviceAddress = _prefs.getPrinterAddressSync();

      if (savedDeviceName != null && savedDeviceAddress != null) {
        // Cari device yang sesuai dengan yang disimpan
        for (var device in _availableDevices) {
          if (device.name == savedDeviceName &&
              device.address == savedDeviceAddress) {
            setState(() {
              _selectedDevice = device;
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error loading saved printer: $e');
    }
  }

  Future<void> _scanBluetoothPrinters() async {
    try {
      List<BluetoothDevice> devices = await printer.getBondedDevices();

      setState(() {
        _availableDevices = devices;
        // Pilih printer default jika belum ada yang dipilih
        if (_selectedDevice == null && devices.isNotEmpty) {
          _selectedDevice = devices.first;
        }
      });

      print('Found ${devices.length} Bluetooth printers');
    } catch (e) {
      print('Error scanning printers: $e');
      setState(() {
        _availableDevices = [];
      });
    }
  }

  Future<bool> _connectToPrinter() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih printer terlebih dahulu')));
      return false;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      // Putuskan koneksi lama jika ada
      await printer.disconnect();
      await Future.delayed(Duration(milliseconds: 500));

      // Koneksi ke printer
      await printer.connect(_selectedDevice!);
      await Future.delayed(Duration(milliseconds: 1000));

      // Verifikasi koneksi
      bool? isConnected = await printer.isConnected;

      setState(() {
        _isConnected = isConnected == true;
        _isConnecting = false;
      });

      return _isConnected;
    } catch (e) {
      print('Connection error: $e');
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });

      return false;
    }
  }

  Future<void> _savePrinterSettings() async {
    try {
      // Simpan pengaturan printer
      if (_selectedDevice != null) {
        await _prefs.setPrinterName(_selectedDevice!.name ?? '');
        await _prefs.setPrinterAddress(_selectedDevice!.address ?? '');
      }

      await _prefs.setPrinterType(_printerType ?? '58mm');

      // Simpan custom text untuk struk
      await _prefs.setNamaPerusahaan(_namaTokoController.text.trim());
      await _prefs.setAlamatPerusahaan(_alamatTokoController.text.trim());
      await _prefs.setTeleponPerusahaan(_teleponTokoController.text.trim());
      await _prefs.setFooterText(_ucapanTerimakasihController.text.trim());
      await _prefs.setCatatanKaki(_catatanKakiController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengaturan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving printer settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testPrinter() async {
    if (!_isConnected) {
      bool connected = await _connectToPrinter();
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung ke printer'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mengirim test ke printer...')));

    try {
      // Reset printer
      await printer.printNewLine();
      await printer.printNewLine();

      // HEADER - Nama Toko
      if (_namaTokoController.text.isNotEmpty) {
        await printer.printCustom(_namaTokoController.text, 3, 1);
        await printer.printNewLine();
      }

      // Alamat Toko
      if (_alamatTokoController.text.isNotEmpty) {
        await printer.printCustom(_alamatTokoController.text, 1, 0);
        await printer.printNewLine();
      }

      // Telepon Toko
      if (_teleponTokoController.text.isNotEmpty) {
        await printer.printCustom('Telp: ${_teleponTokoController.text}', 1, 0);
        await printer.printNewLine();
      }

      // Garis pemisah
      await printer.printCustom('========================', 1, 1);
      await printer.printNewLine();

      // Judul Test
      await printer.printCustom('TEST PRINTER', 2, 1);
      await printer.printNewLine();
      await printer.printCustom(
        'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        1,
        0,
      );
      await printer.printNewLine();
      await printer.printCustom('No. Test: TEST-001', 1, 0);
      await printer.printNewLine();
      await printer.printCustom('Status: SUKSES', 1, 0);

      // Garis pemisah
      await printer.printNewLine();
      await printer.printCustom('========================', 1, 1);
      await printer.printNewLine();

      // FOOTER - Ucapan Terima Kasih
      if (_ucapanTerimakasihController.text.isNotEmpty) {
        await printer.printCustom(_ucapanTerimakasihController.text, 2, 1);
        await printer.printNewLine();
      }

      // Catatan Kaki
      if (_catatanKakiController.text.isNotEmpty) {
        await printer.printCustom(_catatanKakiController.text, 1, 0);
        await printer.printNewLine();
      }

      // Spasi dan potong kertas
      await printer.printNewLine();
      await printer.printNewLine();
      await printer.printNewLine();
      await printer.paperCut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test printer berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error testing printer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim test ke printer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset ke Default'),
        content: Text(
          'Apakah Anda yakin ingin mengembalikan semua pengaturan ke nilai default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyDefaultSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _applyDefaultSettings() {
    setState(() {
      // Default untuk printer thermal 58mm
      _printerType = '58mm';
      _autoPrint = false;
      _duplicatePrint = false;

      // Default untuk custom text
      _namaTokoController.text = 'TOKO KAYU JAYA';
      _alamatTokoController.text = 'Jl. Raya Contoh No. 123, Kota Contoh';
      _teleponTokoController.text = '0812-3456-7890';
      _ucapanTerimakasihController.text = 'TERIMA KASIH TELAH BERBELANJA';
      _catatanKakiController.text =
          'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengaturan telah direset ke default'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Pengaturan')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt),
            onPressed: _resetToDefault,
            tooltip: 'Reset ke Default',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePrinterSettings,
            tooltip: 'Simpan Pengaturan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Status Printer
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.print,
                      color: _isConnected ? Colors.green : Colors.blue,
                      size: 40,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected
                                ? 'Printer Thermal Terhubung'
                                : 'Printer Thermal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isConnected ? Colors.green : Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          if (_selectedDevice != null)
                            Text(
                              '${_selectedDevice!.name ?? 'Printer Thermal'}',
                              style: TextStyle(fontSize: 14),
                            ),
                          if (_printerType != null)
                            Text(
                              'Tipe: ${_printerType == '58mm' ? '58mm (Struk)' : '80mm (Invoice)'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isConnecting)
                      CircularProgressIndicator()
                    else if (!_isConnected)
                      IconButton(
                        icon: Icon(Icons.bluetooth),
                        onPressed: _connectToPrinter,
                        tooltip: 'Hubungkan Printer',
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section: Printer Bluetooth Terdeteksi
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Printer Bluetooth Thermal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: _scanBluetoothPrinters,
                          tooltip: 'Scan Ulang',
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (_availableDevices.isNotEmpty)
                      ..._availableDevices.map((device) {
                        return ListTile(
                          leading: Icon(
                            Icons.print,
                            color: _selectedDevice?.address == device.address
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? ''),
                          trailing: Radio<BluetoothDevice>(
                            value: device,
                            groupValue: _selectedDevice,
                            onChanged: (value) {
                              setState(() {
                                _selectedDevice = value;
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              _selectedDevice = device;
                            });
                          },
                        );
                      }).toList()
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Tidak ada printer Bluetooth terdeteksi',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 5),
                            Text(
                              '1. Pastikan printer thermal dalam keadaan ON\n'
                              '2. Pasangkan (pair) printer dengan perangkat ini\n'
                              '3. Klik tombol scan ulang',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section: Tipe Printer Thermal
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipe Printer Thermal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Pilih tipe printer yang sesuai dengan kertas yang digunakan:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _printerType = '58mm';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _printerType == '58mm'
                                    ? Colors.blue[50]!
                                    : Colors.grey[50]!,
                                border: Border.all(
                                  color: _printerType == '58mm'
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    color: _printerType == '58mm'
                                        ? Colors.blue
                                        : Colors.grey[600]!,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '58mm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _printerType == '58mm'
                                          ? Colors.blue
                                          : Colors.grey[600]!,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Struk Thermal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _printerType == '58mm'
                                          ? Colors.blue
                                          : Colors.grey[600]!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _printerType = '80mm';
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _printerType == '80mm'
                                    ? Colors.blue[50]!
                                    : Colors.grey[50]!,
                                border: Border.all(
                                  color: _printerType == '80mm'
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: _printerType == '80mm'
                                        ? Colors.blue
                                        : Colors.grey[600]!,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '80mm',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _printerType == '80mm'
                                          ? Colors.blue
                                          : Colors.grey[600]!,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Invoice Thermal',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _printerType == '80mm'
                                          ? Colors.blue
                                          : Colors.grey[600]!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Section: Informasi Toko (Header Struk)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Informasi Toko',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Informasi ini akan muncul di bagian atas struk:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _namaTokoController,
                      decoration: InputDecoration(
                        labelText: 'Nama Toko',
                        hintText: 'TOKO KAYU JAYA',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Nama Toko'),
                                content: Text(
                                  'Nama toko akan dicetak dengan huruf besar di bagian atas struk. Contoh: "TOKO KAYU JAYA"',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      maxLength: 40,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _alamatTokoController,
                      decoration: InputDecoration(
                        labelText: 'Alamat Toko',
                        hintText: 'Jl. Raya Contoh No. 123',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      maxLength: 80,
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _teleponTokoController,
                      decoration: InputDecoration(
                        labelText: 'Telepon/WhatsApp',
                        hintText: '0812-3456-7890',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section: Ucapan Terima Kasih (Footer Struk)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.thumb_up, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          'Ucapan Terima Kasih',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ucapan ini akan muncul di bagian bawah struk:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _ucapanTerimakasihController,
                      decoration: InputDecoration(
                        labelText: 'Ucapan Terima Kasih',
                        hintText: 'TERIMA KASIH TELAH BERBELANJA',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.favorite_border),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.info),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Ucapan Terima Kasih'),
                                content: Text(
                                  'Ucapan ini akan dicetak dengan huruf besar di bagian bawah struk. Contoh: "TERIMA KASIH TELAH BERBELANJA"',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      maxLength: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Contoh ucapan yang bisa digunakan:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('TERIMA KASIH'),
                          onDeleted: () {
                            _ucapanTerimakasihController.text = 'TERIMA KASIH';
                          },
                        ),
                        Chip(
                          label: Text('TERIMA KASIH ATAS KUNJUNGANNYA'),
                          onDeleted: () {
                            _ucapanTerimakasihController.text =
                                'TERIMA KASIH ATAS KUNJUNGANNYA';
                          },
                        ),
                        Chip(
                          label: Text('SEMOGA PUAS DENGAN PELAYANAN KAMI'),
                          onDeleted: () {
                            _ucapanTerimakasihController.text =
                                'SEMOGA PUAS DENGAN PELAYANAN KAMI';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section: Catatan Kaki (Footer Tambahan)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, color: Colors.orange),
                        SizedBox(width: 10),
                        Text(
                          'Catatan Kaki Struk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Catatan tambahan di bagian paling bawah struk:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _catatanKakiController,
                      decoration: InputDecoration(
                        labelText: 'Catatan Kaki',
                        hintText:
                            'Barang yang sudah dibeli tidak dapat ditukar/dikembalikan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                      ),
                      maxLines: 2,
                      maxLength: 100,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Contoh catatan yang bisa digunakan:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Barang tidak bisa ditukar/dikembalikan'),
                          onDeleted: () {
                            _catatanKakiController.text =
                                'Barang tidak bisa ditukar/dikembalikan';
                          },
                        ),
                        Chip(
                          label: Text('Simpan struk sebagai bukti pembelian'),
                          onDeleted: () {
                            _catatanKakiController.text =
                                'Simpan struk sebagai bukti pembelian';
                          },
                        ),
                        Chip(
                          label: Text('Harga sudah termasuk PPN'),
                          onDeleted: () {
                            _catatanKakiController.text =
                                'Harga sudah termasuk PPN';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section: Pengaturan Cetak
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan Cetak Otomatis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    SwitchListTile(
                      title: Text('Cetak Otomatis Setiap Transaksi'),
                      subtitle: Text(
                        'Struk otomatis tercetak setelah transaksi disimpan',
                      ),
                      value: _autoPrint,
                      onChanged: (value) async {
                        await _prefs.setAutoPrint(value);
                        setState(() {
                          _autoPrint = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: Text('Cetak Duplikat'),
                      subtitle: Text(
                        'Cetak 2 salinan setiap struk (untuk arsip)',
                      ),
                      value: _duplicatePrint,
                      onChanged: (value) async {
                        await _prefs.setDuplicatePrint(value);
                        setState(() {
                          _duplicatePrint = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Tombol Test Printer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testPrinter,
                icon: Icon(Icons.print),
                label: Text('Test Printer & Preview Struk'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
              ),
            ),

            SizedBox(height: 10),

            // Info Penting
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Informasi Penting:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildInfoItem(
                      '🎯',
                      'Printer Thermal 58mm: cocok untuk struk pembelian/penjualan',
                    ),
                    _buildInfoItem(
                      '📄',
                      'Printer Thermal 80mm: cocok untuk invoice dan laporan detail',
                    ),
                    _buildInfoItem(
                      '🔋',
                      'Pastikan printer thermal dalam keadaan hidup dan ada kertas',
                    ),
                    _buildInfoItem(
                      '📱',
                      'Untuk printer Bluetooth, pastikan sudah dipasangkan (paired)',
                    ),
                    _buildInfoItem(
                      '💾',
                      'Simpan pengaturan setelah melakukan perubahan',
                    ),
                    _buildInfoItem(
                      '🖨️',
                      'Test printer untuk melihat preview struk sebelum digunakan',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 16)),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
