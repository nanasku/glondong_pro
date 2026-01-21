import 'package:flutter/material.dart';
import 'package:tpk_app/services/database_service.dart';

class MasterJualPage extends StatefulWidget {
  const MasterJualPage({Key? key}) : super(key: key);

  @override
  _MasterJualPageState createState() => _MasterJualPageState();
}

class _MasterJualPageState extends State<MasterJualPage> {
  // ✅ Labels untuk harga
  final Map<String, String> priceLabels = {
    'Rijek 1': 'Harga Rijek 1 (D 10-14)',
    'Rijek 2': 'Harga Rijek 2 (D 15-19)',
    'Standar': 'Harga Standar (D 20 Up)',
    'Super A': 'Harga Super A Custom',
    'Super B': 'Harga Super B Custom',
    'Super C': 'Harga Super C (D 25 Up)',
  };

  List<Map<String, dynamic>> products = [];
  List<String> availableKayuNames = []; // List untuk nama kayu yang tersedia
  List<Map<String, dynamic>> availablePembeli =
      []; // List untuk pembeli yang tersedia
  bool isLoading = true;
  bool isLoadingKayuNames = true;
  bool isLoadingPembeli = true;
  String errorMessage = '';

  final DatabaseService _databaseService = DatabaseService();

  // Fungsi untuk memformat harga tanpa .00
  String formatPrice(dynamic value) {
    if (value == null) return '0';

    int number;
    if (value is String) {
      number = int.tryParse(value) ?? 0;
    } else if (value is double) {
      number = value.toInt();
    } else {
      number = value;
    }

    return number.toString();
  }

  @override
  void initState() {
    super.initState();
    _fetchAvailableData();
    _fetchProducts();
  }

  // Fungsi untuk mengambil data yang dibutuhkan
  Future<void> _fetchAvailableData() async {
    try {
      final db = await _databaseService.database;

      // 1. Ambil nama kayu yang unik dari tabel harga_beli
      final List<Map<String, dynamic>> kayuData = await db.query(
        'harga_beli',
        columns: ['nama_kayu'],
        orderBy: 'nama_kayu ASC',
      );

      // Extract nama kayu yang unik
      Set<String> uniqueKayuNames = Set<String>();
      for (var row in kayuData) {
        if (row['nama_kayu'] != null &&
            row['nama_kayu'].toString().isNotEmpty) {
          uniqueKayuNames.add(row['nama_kayu'].toString());
        }
      }

      // Jika ada data di harga_jual yang belum ada di harga_beli, tambahkan juga
      final List<Map<String, dynamic>> existingJualData = await db.query(
        'harga_jual',
        columns: ['nama_kayu'],
        orderBy: 'nama_kayu ASC',
      );

      for (var row in existingJualData) {
        if (row['nama_kayu'] != null &&
            row['nama_kayu'].toString().isNotEmpty) {
          uniqueKayuNames.add(row['nama_kayu'].toString());
        }
      }

      // 2. Ambil data pembeli dari tabel pembeli
      final List<Map<String, dynamic>> pembeliData = await db.query(
        'pembeli',
        orderBy: 'nama ASC',
      );

      setState(() {
        availableKayuNames = uniqueKayuNames.toList()..sort();
        availablePembeli = pembeliData;
        isLoadingKayuNames = false;
        isLoadingPembeli = false;
      });
    } catch (e) {
      setState(() {
        isLoadingKayuNames = false;
        isLoadingPembeli = false;
      });
      print('Error fetching data: $e');
    }
  }

  // Fungsi untuk mengambil data produk dari SQLite
  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> data = await db.query(
        'harga_jual',
        orderBy: 'nama_kayu ASC',
      );

      // Convert ke format yang compatible dengan existing code
      List<Map<String, dynamic>> convertedData = data.map((row) {
        return {
          'id': row['id'],
          'nama_kayu': row['nama_kayu'],
          'pembeli_id': row['pembeli_id'],
          'prices': {
            'Rijek 1': row['harga_rijek_1'],
            'Rijek 2': row['harga_rijek_2'],
            'Standar': row['harga_standar'],
            'Super A': row['harga_super_a'],
            'Super B': row['harga_super_b'],
            'Super C': row['harga_super_c'],
          },
        };
      }).toList();

      setState(() {
        products = convertedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: $e';
      });
    }
  }

  // Fungsi untuk menambah produk baru
  Future<void> _addProduct(Map<String, dynamic> newProduct) async {
    try {
      final db = await _databaseService.database;

      // Convert prices format ke kolom database
      final Map<String, dynamic> prices = newProduct['prices'];

      await db.insert('harga_jual', {
        'nama_kayu': newProduct['nama_kayu'],
        'pembeli_id': newProduct['pembeli_id'],
        'harga_rijek_1':
            int.tryParse(prices['Rijek 1']?.toString() ?? '0') ?? 0,
        'harga_rijek_2':
            int.tryParse(prices['Rijek 2']?.toString() ?? '0') ?? 0,
        'harga_standar':
            int.tryParse(prices['Standar']?.toString() ?? '0') ?? 0,
        'harga_super_a':
            int.tryParse(prices['Super A']?.toString() ?? '0') ?? 0,
        'harga_super_b':
            int.tryParse(prices['Super B']?.toString() ?? '0') ?? 0,
        'harga_super_c':
            int.tryParse(prices['Super C']?.toString() ?? '0') ?? 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Refresh data setelah berhasil menambah
      _fetchProducts();
      _fetchAvailableData(); // Refresh list nama kayu dan pembeli
    } catch (e) {
      throw Exception('Gagal menambah kayu: $e');
    }
  }

  // Fungsi untuk mengupdate produk
  Future<void> _updateProduct(Map<String, dynamic> updatedProduct) async {
    try {
      final db = await _databaseService.database;

      // Convert prices format ke kolom database
      final Map<String, dynamic> prices = updatedProduct['prices'];

      await db.update(
        'harga_jual',
        {
          'nama_kayu': updatedProduct['nama_kayu'],
          'pembeli_id': updatedProduct['pembeli_id'],
          'harga_rijek_1':
              int.tryParse(prices['Rijek 1']?.toString() ?? '0') ?? 0,
          'harga_rijek_2':
              int.tryParse(prices['Rijek 2']?.toString() ?? '0') ?? 0,
          'harga_standar':
              int.tryParse(prices['Standar']?.toString() ?? '0') ?? 0,
          'harga_super_a':
              int.tryParse(prices['Super A']?.toString() ?? '0') ?? 0,
          'harga_super_b':
              int.tryParse(prices['Super B']?.toString() ?? '0') ?? 0,
          'harga_super_c':
              int.tryParse(prices['Super C']?.toString() ?? '0') ?? 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [updatedProduct['id']],
      );

      // Refresh data setelah berhasil update
      _fetchProducts();
      _fetchAvailableData(); // Refresh list nama kayu dan pembeli
    } catch (e) {
      throw Exception('Gagal mengupdate kayu: $e');
    }
  }

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(int id) async {
    try {
      final db = await _databaseService.database;

      await db.delete('harga_jual', where: 'id = ?', whereArgs: [id]);

      // Refresh data setelah berhasil menghapus
      _fetchProducts();
      _fetchAvailableData(); // Refresh list nama kayu dan pembeli
    } catch (e) {
      throw Exception('Gagal menghapus kayu: $e');
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    Map<String, TextEditingController> controllers = {};

    // Initialize controllers with current values (format tanpa .00)
    product['prices'].forEach((key, value) {
      controllers[key] = TextEditingController(text: formatPrice(value));
    });

    String? selectedKayuName = product['nama_kayu'];
    String? selectedPembeliId = product['pembeli_id']?.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Harga Kayu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown untuk memilih pembeli
                DropdownButtonFormField<String>(
                  value: selectedPembeliId,
                  decoration: InputDecoration(
                    labelText: 'Nama Pembeli',
                    border: OutlineInputBorder(),
                  ),
                  items: availablePembeli.map((pembeli) {
                    return DropdownMenuItem<String>(
                      value: pembeli['id'].toString(),
                      child: Text(pembeli['nama'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPembeliId = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih nama pembeli';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Dropdown untuk memilih nama kayu
                DropdownButtonFormField<String>(
                  value: selectedKayuName,
                  decoration: InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
                  items: availableKayuNames.map((String kayuName) {
                    return DropdownMenuItem<String>(
                      value: kayuName,
                      child: Text(kayuName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedKayuName = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pilih nama kayu';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                ...product['prices'].keys.map((priceKey) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: controllers[priceKey],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: priceLabels[priceKey] ?? 'Harga $priceKey',
                        border: OutlineInputBorder(),
                        prefixText: 'Rp ',
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi input
                if (selectedPembeliId == null || selectedPembeliId!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama pembeli harus dipilih')),
                  );
                  return;
                }

                if (selectedKayuName == null || selectedKayuName!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama kayu harus dipilih')),
                  );
                  return;
                }

                // Update product data
                final updatedProduct = {
                  'id': product['id'],
                  'nama_kayu': selectedKayuName!,
                  'pembeli_id': int.parse(selectedPembeliId!),
                  'prices': {},
                };

                controllers.forEach((key, controller) {
                  updatedProduct['prices'][key] = controller.text.isEmpty
                      ? '0'
                      : controller.text;
                });

                try {
                  await _updateProduct(updatedProduct);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kayu berhasil diupdate')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengupdate kayu: $e')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductDialog() {
    Map<String, TextEditingController> controllers = {};
    List<String> priceTypes = [
      'Rijek 1',
      'Rijek 2',
      'Standar',
      'Super A',
      'Super B',
      'Super C',
    ];

    // Initialize controllers with empty values
    for (var priceType in priceTypes) {
      controllers[priceType] = TextEditingController();
    }

    String? selectedKayuName;
    String? selectedPembeliId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Tambah Harga Jual'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropdown untuk memilih pembeli
                    DropdownButtonFormField<String>(
                      value: selectedPembeliId,
                      decoration: InputDecoration(
                        labelText: 'Nama Pembeli *',
                        border: OutlineInputBorder(),
                      ),
                      items: availablePembeli.map((pembeli) {
                        return DropdownMenuItem<String>(
                          value: pembeli['id'].toString(),
                          child: Text(pembeli['nama'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedPembeliId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih nama pembeli';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Dropdown untuk memilih nama kayu
                    DropdownButtonFormField<String>(
                      value: selectedKayuName,
                      decoration: InputDecoration(
                        labelText: 'Nama Kayu *',
                        border: OutlineInputBorder(),
                      ),
                      items: availableKayuNames.map((String kayuName) {
                        return DropdownMenuItem<String>(
                          value: kayuName,
                          child: Text(kayuName),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateDialog(() {
                          selectedKayuName = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pilih nama kayu';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),
                    if (availableKayuNames.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Belum ada data kayu. Tambahkan data kayu di Master Beli terlebih dahulu.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),

                    if (availablePembeli.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Belum ada data pembeli. Tambahkan data pembeli terlebih dahulu.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),

                    ...priceTypes.map((priceKey) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          controller: controllers[priceKey],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                priceLabels[priceKey] ?? 'Harga $priceKey',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validasi input
                    if (selectedPembeliId == null ||
                        selectedPembeliId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Nama pembeli harus dipilih')),
                      );
                      return;
                    }

                    if (selectedKayuName == null || selectedKayuName!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Nama kayu harus dipilih')),
                      );
                      return;
                    }

                    // Validasi jika tidak ada data kayu sama sekali
                    if (availableKayuNames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tidak ada data kayu. Tambahkan data kayu di Master Beli terlebih dahulu.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Validasi jika tidak ada data pembeli
                    if (availablePembeli.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Tidak ada data pembeli. Tambahkan data pembeli terlebih dahulu.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Add new product
                    Map<String, String> prices = {};
                    controllers.forEach((key, controller) {
                      prices[key] = controller.text.isEmpty
                          ? '0'
                          : controller.text;
                    });

                    final newProduct = {
                      'nama_kayu': selectedKayuName!,
                      'pembeli_id': int.parse(selectedPembeliId!),
                      'prices': prices,
                    };

                    try {
                      await _addProduct(newProduct);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Harga jual berhasil ditambahkan'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menambah harga jual: $e'),
                        ),
                      );
                    }
                  },
                  child: Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int id, String nama_kayu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Harga Jual'),
          content: Text(
            'Apakah Anda yakin ingin menghapus harga jual untuk $nama_kayu?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _deleteProduct(id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Harga jual berhasil dihapus')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus harga jual: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk mendapatkan nama pembeli berdasarkan ID
  String getPembeliName(int? pembeliId) {
    if (pembeliId == null) return '-';
    final pembeli = availablePembeli.firstWhere(
      (p) => p['id'] == pembeliId,
      orElse: () => {'nama': '-'},
    );
    return pembeli['nama'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Harga Jual'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _fetchAvailableData();
              _fetchProducts();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: availableKayuNames.isEmpty || availablePembeli.isEmpty
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          availableKayuNames.isEmpty
                              ? 'Tidak ada data kayu. Tambahkan data kayu di Master Beli terlebih dahulu.'
                              : 'Tidak ada data pembeli. Tambahkan data pembeli terlebih dahulu.',
                        ),
                      ),
                    );
                  }
                : _showAddProductDialog,
            tooltip: availableKayuNames.isEmpty || availablePembeli.isEmpty
                ? 'Data tidak lengkap'
                : 'Tambah Harga Jual',
          ),
        ],
      ),
      body: isLoading || isLoadingKayuNames || isLoadingPembeli
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _fetchAvailableData();
                      _fetchProducts();
                    },
                    child: Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    availableKayuNames.isEmpty
                        ? 'Belum ada data kayu di Master Beli'
                        : availablePembeli.isEmpty
                        ? 'Belum ada data pembeli'
                        : 'Belum ada data harga jual',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    availableKayuNames.isEmpty
                        ? 'Tambahkan data kayu di Master Beli terlebih dahulu'
                        : availablePembeli.isEmpty
                        ? 'Tambahkan data pembeli terlebih dahulu'
                        : 'Tap + untuk menambah data baru',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
      floatingActionButton:
          availableKayuNames.isEmpty || availablePembeli.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _showAddProductDialog,
              child: Icon(Icons.add),
              tooltip: 'Tambah Harga Jual Baru',
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.forest, color: Colors.green),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['nama_kayu'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Pembeli: ${getPembeliName(product['pembeli_id'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Rijek 1: Rp ${formatPrice(product['prices']['Rijek 1'])}'),
            Text('Rijek 2: Rp ${formatPrice(product['prices']['Rijek 2'])}'),
            Text('Standar: Rp ${formatPrice(product['prices']['Standar'])}'),
            if (int.parse(formatPrice(product['prices']['Super A'] ?? '0')) > 0)
              Text('Super A: Rp ${formatPrice(product['prices']['Super A'])}'),
            if (int.parse(formatPrice(product['prices']['Super B'] ?? '0')) > 0)
              Text('Super B: Rp ${formatPrice(product['prices']['Super B'])}'),
            if (int.parse(formatPrice(product['prices']['Super C'] ?? '0')) > 0)
              Text('Super C: Rp ${formatPrice(product['prices']['Super C'])}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                _showEditProductDialog(product);
              },
              tooltip: 'Edit Harga Jual',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(
                  product['id'] as int,
                  product['nama_kayu'] as String,
                );
              },
              tooltip: 'Hapus Harga Jual',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up resources jika diperlukan
    super.dispose();
  }
}
