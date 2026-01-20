import 'package:flutter/material.dart';
import 'package:tpk_app/services/database_service.dart';

class PembeliPage extends StatefulWidget {
  const PembeliPage({Key? key}) : super(key: key);

  @override
  State<PembeliPage> createState() => _PembeliPageState();
}

class _PembeliPageState extends State<PembeliPage> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();

  List<Map<String, dynamic>> _dataPembeli = [];
  int? _editingId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _dbService.initializeDatabase();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _dbService.getAllPembeli();
      setState(() {
        _dataPembeli = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Gagal memuat data: $e');
    }
  }

  void _resetForm() {
    _namaController.clear();
    _alamatController.clear();
    _teleponController.clear();
    _editingId = null;
  }

  Future<void> _savePembeli() async {
    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();
    final telepon = _teleponController.text.trim();

    if (nama.isEmpty) {
      _showError("Nama pembeli tidak boleh kosong");
      return;
    }

    try {
      if (_editingId == null) {
        // INSERT
        await _dbService.insertPembeli({
          'nama': nama,
          'alamat': alamat,
          'telepon': telepon,
          'created_at': DateTime.now().toIso8601String(),
        });
        _showSuccess('Pembeli berhasil ditambahkan');
      } else {
        // UPDATE
        await _dbService.updatePembeli(_editingId!, {
          'nama': nama,
          'alamat': alamat,
          'telepon': telepon,
        });
        _showSuccess('Pembeli berhasil diperbarui');
      }

      _resetForm();
      _refreshData();
    } catch (e) {
      _showError('Gagal menyimpan data: $e');
    }
  }

  Future<void> _deletePembeli(int id) async {
    try {
      await _dbService.deletePembeli(id);
      _showSuccess('Pembeli berhasil dihapus');
      _refreshData();
    } catch (e) {
      _showError('Gagal menghapus data: $e');
    }
  }

  void _editPembeli(Map<String, dynamic> pembeli) {
    setState(() {
      _editingId = pembeli['id'];
      _namaController.text = pembeli['nama'] ?? '';
      _alamatController.text = pembeli['alamat'] ?? '';
      _teleponController.text = pembeli['telepon'] ?? '';
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Pembeli"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // FORM INPUT
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Pembeli',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _alamatController,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _teleponController,
                        decoration: const InputDecoration(
                          labelText: 'Telepon',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _savePembeli,
                            icon: const Icon(Icons.save),
                            label: Text(
                              _editingId == null ? 'Simpan' : 'Update',
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.clear),
                            label: const Text('Batal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Daftar Pembeli",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),

              Container(
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dataPembeli.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text("Belum ada data pembeli"),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _dataPembeli.length,
                        itemBuilder: (context, index) {
                          final pembeli = _dataPembeli[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  (pembeli['nama'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(pembeli['nama'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Alamat: ${pembeli['alamat'] ?? '-'}"),
                                  Text("Telepon: ${pembeli['telepon'] ?? '-'}"),
                                  if (pembeli['created_at'] != null)
                                    Text(
                                      "Ditambahkan: ${_formatDate(pembeli['created_at'])}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _editPembeli(pembeli),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Hapus Data'),
                                          content: const Text(
                                            'Yakin ingin menghapus pembeli ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Hapus'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _deletePembeli(pembeli['id']);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
