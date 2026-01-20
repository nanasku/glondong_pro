import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tpk_app/services/database_service.dart';

class OperasionalTPKPage extends StatefulWidget {
  const OperasionalTPKPage({super.key});

  @override
  State<OperasionalTPKPage> createState() => _OperasionalTPKPageState();
}

class _OperasionalTPKPageState extends State<OperasionalTPKPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _jenisBiayaController = TextEditingController();
  final TextEditingController _jumlahBiayaController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  List<Map<String, dynamic>> _listBiayaLain = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedJenisBiaya;

  final List<String> _defaultJenisBiaya = [
    'Biaya Listrik',
    'Biaya Air',
    'Biaya Telepon/Internet',
    'Biaya Transportasi',
    'Biaya Perawatan Kendaraan',
    'Biaya Perbaikan Alat',
    'Biaya Administrasi',
    'Biaya Sewa Tempat',
    'Biaya Gaji Karyawan',
    'Biaya Lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _databaseService.getAllBiayaLain();
      setState(() {
        _listBiayaLain = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _tambahBiayaLain() async {
    final jenisBiaya = _selectedJenisBiaya ?? _jenisBiayaController.text;

    if (jenisBiaya.isEmpty || _jumlahBiayaController.text.isEmpty) {
      _showSnackBar('Jenis biaya dan jumlah biaya harus diisi');
      return;
    }

    try {
      final jumlahBiaya = int.tryParse(_jumlahBiayaController.text) ?? 0;
      if (jumlahBiaya <= 0) {
        _showSnackBar('Jumlah biaya harus lebih dari 0');
        return;
      }

      final data = {
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'jenis_biaya': jenisBiaya,
        'jumlah_biaya': jumlahBiaya,
        'keterangan': _keteranganController.text,
      };

      await _databaseService.insertBiayaLain(data);

      _showSnackBar('Biaya berhasil ditambahkan');
      _resetForm();
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _resetForm() {
    _jenisBiayaController.clear();
    _jumlahBiayaController.clear();
    _keteranganController.clear();
    _selectedDate = DateTime.now();
    _selectedJenisBiaya = null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showDeleteConfirmation(int id) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data biaya ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteBiayaLain(id);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBiayaLain(int id) async {
    try {
      await _databaseService.deleteBiayaLain(id);
      _showSnackBar('Data biaya berhasil dihapus');
      await _loadData();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  int _getTotalBiaya() {
    return _listBiayaLain.fold(
      0,
      (sum, item) => sum + (item['jumlah_biaya'] as int),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operasional TPK'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Input
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tambah Biaya Operasional',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tanggal
                          Row(
                            children: [
                              const Text(
                                'Tanggal:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: _showDatePicker,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Jenis Biaya - Dropdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jenis Biaya:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedJenisBiaya,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  hint: const Text('Pilih Jenis Biaya'),
                                  items: _defaultJenisBiaya.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedJenisBiaya = newValue;
                                      _jenisBiayaController.clear();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Atau
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'ATAU',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Input Manual Jenis Biaya
                          TextField(
                            controller: _jenisBiayaController,
                            decoration: const InputDecoration(
                              labelText: 'Ketik jenis biaya manual',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  _selectedJenisBiaya = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Jumlah Biaya
                          TextField(
                            controller: _jumlahBiayaController,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah Biaya (Rp)',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Keterangan
                          TextField(
                            controller: _keteranganController,
                            decoration: const InputDecoration(
                              labelText: 'Keterangan (Opsional)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),

                          // Tombol Simpan
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _tambahBiayaLain,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Simpan Biaya Operasional',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total Biaya
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Biaya Operasional:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatCurrency(_getTotalBiaya()),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Daftar Biaya
                  const Text(
                    'Riwayat Biaya Operasional',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _listBiayaLain.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada data biaya operasional',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _listBiayaLain.length,
                          itemBuilder: (context, index) {
                            final item = _listBiayaLain[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item['jenis_biaya']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                        DateTime.parse(
                                          item['tanggal']?.toString() ??
                                              DateTime.now().toString(),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (item['keterangan']
                                            ?.toString()
                                            .isNotEmpty ??
                                        false) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item['keterangan']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(
                                        item['jumlah_biaya'] as int,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showDeleteConfirmation(
                                        item['id'] as int,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
