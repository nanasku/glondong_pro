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
  bool isLoading = true;
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
    _fetchProducts();
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
    } catch (e) {
      throw Exception('Gagal menambah produk: $e');
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
    } catch (e) {
      throw Exception('Gagal mengupdate produk: $e');
    }
  }

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(int id) async {
    try {
      final db = await _databaseService.database;

      await db.delete('harga_jual', where: 'id = ?', whereArgs: [id]);

      // Refresh data setelah berhasil menghapus
      _fetchProducts();
    } catch (e) {
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    Map<String, TextEditingController> controllers = {};

    // Initialize controllers with current values (format tanpa .00)
    product['prices'].forEach((key, value) {
      controllers[key] = TextEditingController(text: formatPrice(value));
    });

    TextEditingController nameController = TextEditingController(
      text: product['nama_kayu'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Harga Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama kayu harus diisi')),
                  );
                  return;
                }

                // Update product data
                final updatedProduct = {
                  'id': product['id'],
                  'nama_kayu': nameController.text,
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
                    SnackBar(content: Text('Produk berhasil diupdate')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengupdate produk: $e')),
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

    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kayu',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ...priceTypes.map((priceKey) {
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama kayu harus diisi')),
                  );
                  return;
                }

                // Add new product
                Map<String, String> prices = {};
                controllers.forEach((key, controller) {
                  prices[key] = controller.text.isEmpty ? '0' : controller.text;
                });

                final newProduct = {
                  'nama_kayu': nameController.text,
                  'prices': prices,
                };

                try {
                  await _addProduct(newProduct);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk berhasil ditambahkan')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menambah produk: $e')),
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

  void _showDeleteConfirmationDialog(int id, String nama_kayu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Produk'),
          content: Text('Apakah Anda yakin ingin menghapus $nama_kayu?'),
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
                    SnackBar(content: Text('Produk berhasil dihapus')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus produk: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Harga Jual'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchProducts,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddProductDialog,
            tooltip: 'Tambah Produk',
          ),
        ],
      ),
      body: isLoading
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
                    onPressed: _fetchProducts,
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
                    'Belum ada data harga jual',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + untuk menambah data baru',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
        tooltip: 'Tambah Produk Baru',
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
        title: Text(
          product['nama_kayu'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Rijek 1: Rp ${formatPrice(product['prices']['Rijek 1'])}'),
            Text('Rijek 2: Rp ${formatPrice(product['prices']['Rijek 2'])}'),
            Text('Standar: Rp ${formatPrice(product['prices']['Standar'])}'),
            if (int.parse(formatPrice(product['prices']['Super A'])) > 0)
              Text('Super A: Rp ${formatPrice(product['prices']['Super A'])}'),
            if (int.parse(formatPrice(product['prices']['Super B'])) > 0)
              Text('Super B: Rp ${formatPrice(product['prices']['Super B'])}'),
            if (int.parse(formatPrice(product['prices']['Super C'])) > 0)
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
              tooltip: 'Edit Produk',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(
                  product['id'],
                  product['nama_kayu'],
                );
              },
              tooltip: 'Hapus Produk',
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
