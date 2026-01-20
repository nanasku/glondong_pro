import 'package:flutter/material.dart';
import 'package:tpk_app/services/database_service.dart';

class MasterBeliPage extends StatefulWidget {
  const MasterBeliPage({Key? key}) : super(key: key);

  @override
  _MasterBeliPageState createState() => _MasterBeliPageState();
}

class _MasterBeliPageState extends State<MasterBeliPage> {
  // ✅ Labels untuk harga
  final Map<String, String> priceLabels = {
    'harga_rijek_1': 'Harga Rijek 1 (D 10-14)',
    'harga_rijek_2': 'Harga Rijek 2 (D 15-19)',
    'harga_standar': 'Harga Standar (D 20 Up)',
    'harga_super_a': 'Harga Super A Custom',
    'harga_super_b': 'Harga Super B Custom',
    'harga_super_c': 'Harga Super C (D 25 Up)',
  };

  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String errorMessage = '';

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
      final db = await DatabaseService().database;
      final data = await db.query('harga_beli', orderBy: 'nama_kayu ASC');

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  // Fungsi untuk menambah produk baru dengan level harga
  Future<void> _addProduct(Map<String, dynamic> newProduct) async {
    try {
      final db = await DatabaseService().database;
      await db.insert('harga_beli', {
        'nama_kayu': newProduct['nama_kayu'],
        // Rijek 1 dengan level
        'harga_rijek_1': int.tryParse(newProduct['harga_rijek_1'] ?? '0') ?? 0,
        'harga_rijek_1_level1':
            int.tryParse(newProduct['harga_rijek_1_level1'] ?? '0') ?? 0,
        'harga_rijek_1_level2':
            int.tryParse(newProduct['harga_rijek_1_level2'] ?? '0') ?? 0,
        'harga_rijek_1_level3':
            int.tryParse(newProduct['harga_rijek_1_level3'] ?? '0') ?? 0,

        // Rijek 2 dengan level
        'harga_rijek_2': int.tryParse(newProduct['harga_rijek_2'] ?? '0') ?? 0,
        'harga_rijek_2_level1':
            int.tryParse(newProduct['harga_rijek_2_level1'] ?? '0') ?? 0,
        'harga_rijek_2_level2':
            int.tryParse(newProduct['harga_rijek_2_level2'] ?? '0') ?? 0,
        'harga_rijek_2_level3':
            int.tryParse(newProduct['harga_rijek_2_level3'] ?? '0') ?? 0,

        // Standar dengan level
        'harga_standar': int.tryParse(newProduct['harga_standar'] ?? '0') ?? 0,
        'harga_standar_level1':
            int.tryParse(newProduct['harga_standar_level1'] ?? '0') ?? 0,
        'harga_standar_level2':
            int.tryParse(newProduct['harga_standar_level2'] ?? '0') ?? 0,
        'harga_standar_level3':
            int.tryParse(newProduct['harga_standar_level3'] ?? '0') ?? 0,

        // Super A dengan level
        'harga_super_a': int.tryParse(newProduct['harga_super_a'] ?? '0') ?? 0,
        'harga_super_a_level1':
            int.tryParse(newProduct['harga_super_a_level1'] ?? '0') ?? 0,
        'harga_super_a_level2':
            int.tryParse(newProduct['harga_super_a_level2'] ?? '0') ?? 0,
        'harga_super_a_level3':
            int.tryParse(newProduct['harga_super_a_level3'] ?? '0') ?? 0,

        // Super B dengan level
        'harga_super_b': int.tryParse(newProduct['harga_super_b'] ?? '0') ?? 0,
        'harga_super_b_level1':
            int.tryParse(newProduct['harga_super_b_level1'] ?? '0') ?? 0,
        'harga_super_b_level2':
            int.tryParse(newProduct['harga_super_b_level2'] ?? '0') ?? 0,
        'harga_super_b_level3':
            int.tryParse(newProduct['harga_super_b_level3'] ?? '0') ?? 0,

        // Super C dengan level
        'harga_super_c': int.tryParse(newProduct['harga_super_c'] ?? '0') ?? 0,
        'harga_super_c_level1':
            int.tryParse(newProduct['harga_super_c_level1'] ?? '0') ?? 0,
        'harga_super_c_level2':
            int.tryParse(newProduct['harga_super_c_level2'] ?? '0') ?? 0,
        'harga_super_c_level3':
            int.tryParse(newProduct['harga_super_c_level3'] ?? '0') ?? 0,

        'created_at': DateTime.now().toString(),
        'updated_at': DateTime.now().toString(),
      });

      // Refresh data setelah berhasil menambah
      _fetchProducts();
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk mengupdate produk dengan level harga
  Future<void> _updateProduct(Map<String, dynamic> updatedProduct) async {
    try {
      final db = await DatabaseService().database;
      await db.update(
        'harga_beli',
        {
          'nama_kayu': updatedProduct['nama_kayu'],

          // Rijek 1 dengan level
          'harga_rijek_1':
              int.tryParse(updatedProduct['harga_rijek_1'] ?? '0') ?? 0,
          'harga_rijek_1_level1':
              int.tryParse(updatedProduct['harga_rijek_1_level1'] ?? '0') ?? 0,
          'harga_rijek_1_level2':
              int.tryParse(updatedProduct['harga_rijek_1_level2'] ?? '0') ?? 0,
          'harga_rijek_1_level3':
              int.tryParse(updatedProduct['harga_rijek_1_level3'] ?? '0') ?? 0,

          // Rijek 2 dengan level
          'harga_rijek_2':
              int.tryParse(updatedProduct['harga_rijek_2'] ?? '0') ?? 0,
          'harga_rijek_2_level1':
              int.tryParse(updatedProduct['harga_rijek_2_level1'] ?? '0') ?? 0,
          'harga_rijek_2_level2':
              int.tryParse(updatedProduct['harga_rijek_2_level2'] ?? '0') ?? 0,
          'harga_rijek_2_level3':
              int.tryParse(updatedProduct['harga_rijek_2_level3'] ?? '0') ?? 0,

          // Standar dengan level
          'harga_standar':
              int.tryParse(updatedProduct['harga_standar'] ?? '0') ?? 0,
          'harga_standar_level1':
              int.tryParse(updatedProduct['harga_standar_level1'] ?? '0') ?? 0,
          'harga_standar_level2':
              int.tryParse(updatedProduct['harga_standar_level2'] ?? '0') ?? 0,
          'harga_standar_level3':
              int.tryParse(updatedProduct['harga_standar_level3'] ?? '0') ?? 0,

          // Super A dengan level
          'harga_super_a':
              int.tryParse(updatedProduct['harga_super_a'] ?? '0') ?? 0,
          'harga_super_a_level1':
              int.tryParse(updatedProduct['harga_super_a_level1'] ?? '0') ?? 0,
          'harga_super_a_level2':
              int.tryParse(updatedProduct['harga_super_a_level2'] ?? '0') ?? 0,
          'harga_super_a_level3':
              int.tryParse(updatedProduct['harga_super_a_level3'] ?? '0') ?? 0,

          // Super B dengan level
          'harga_super_b':
              int.tryParse(updatedProduct['harga_super_b'] ?? '0') ?? 0,
          'harga_super_b_level1':
              int.tryParse(updatedProduct['harga_super_b_level1'] ?? '0') ?? 0,
          'harga_super_b_level2':
              int.tryParse(updatedProduct['harga_super_b_level2'] ?? '0') ?? 0,
          'harga_super_b_level3':
              int.tryParse(updatedProduct['harga_super_b_level3'] ?? '0') ?? 0,

          // Super C dengan level
          'harga_super_c':
              int.tryParse(updatedProduct['harga_super_c'] ?? '0') ?? 0,
          'harga_super_c_level1':
              int.tryParse(updatedProduct['harga_super_c_level1'] ?? '0') ?? 0,
          'harga_super_c_level2':
              int.tryParse(updatedProduct['harga_super_c_level2'] ?? '0') ?? 0,
          'harga_super_c_level3':
              int.tryParse(updatedProduct['harga_super_c_level3'] ?? '0') ?? 0,

          'updated_at': DateTime.now().toString(),
        },
        where: 'id = ?',
        whereArgs: [updatedProduct['id']],
      );

      // Refresh data setelah berhasil update
      _fetchProducts();
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Fungsi untuk menghapus produk
  Future<void> _deleteProduct(int id) async {
    try {
      final db = await DatabaseService().database;
      await db.delete('harga_beli', where: 'id = ?', whereArgs: [id]);

      // Refresh data setelah berhasil menghapus
      _fetchProducts();
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Widget untuk menampilkan input harga dengan level
  Widget _buildPriceLevelInputs({
    required String category,
    required Map<String, TextEditingController> controllers,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        SizedBox(height: 8),

        // Harga Dasar
        TextField(
          controller: controllers[category],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Harga Dasar',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controllers['${category}_level1'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Level 1',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers['${category}_level2'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Level 2',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controllers['${category}_level3'],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Level 3',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    Map<String, TextEditingController> controllers = {};

    // Initialize controllers with current values (format tanpa .00)
    controllers['harga_rijek_1'] = TextEditingController(
      text: formatPrice(product['harga_rijek_1']),
    );
    controllers['harga_rijek_1_level1'] = TextEditingController(
      text: formatPrice(product['harga_rijek_1_level1'] ?? '0'),
    );
    controllers['harga_rijek_1_level2'] = TextEditingController(
      text: formatPrice(product['harga_rijek_1_level2'] ?? '0'),
    );
    controllers['harga_rijek_1_level3'] = TextEditingController(
      text: formatPrice(product['harga_rijek_1_level3'] ?? '0'),
    );

    controllers['harga_rijek_2'] = TextEditingController(
      text: formatPrice(product['harga_rijek_2']),
    );
    controllers['harga_rijek_2_level1'] = TextEditingController(
      text: formatPrice(product['harga_rijek_2_level1'] ?? '0'),
    );
    controllers['harga_rijek_2_level2'] = TextEditingController(
      text: formatPrice(product['harga_rijek_2_level1'] ?? '0'),
    );
    controllers['harga_rijek_2_level3'] = TextEditingController(
      text: formatPrice(product['harga_rijek_2_level1'] ?? '0'),
    );

    controllers['harga_standar'] = TextEditingController(
      text: formatPrice(product['harga_standar']),
    );
    controllers['harga_standar_level1'] = TextEditingController(
      text: formatPrice(product['harga_standar_level1'] ?? '0'),
    );
    controllers['harga_standar_level2'] = TextEditingController(
      text: formatPrice(product['harga_standar_level2'] ?? '0'),
    );
    controllers['harga_standar_level3'] = TextEditingController(
      text: formatPrice(product['harga_standar_level3'] ?? '0'),
    );

    controllers['harga_super_a'] = TextEditingController(
      text: formatPrice(product['harga_super_a']),
    );
    controllers['harga_super_a_level1'] = TextEditingController(
      text: formatPrice(product['harga_super_a_level1'] ?? '0'),
    );
    controllers['harga_super_a_level2'] = TextEditingController(
      text: formatPrice(product['harga_super_a_level2'] ?? '0'),
    );
    controllers['harga_super_a_level3'] = TextEditingController(
      text: formatPrice(product['harga_super_a_level3'] ?? '0'),
    );

    controllers['harga_super_b'] = TextEditingController(
      text: formatPrice(product['harga_super_b']),
    );
    controllers['harga_super_b_level1'] = TextEditingController(
      text: formatPrice(product['harga_super_b_level1'] ?? '0'),
    );
    controllers['harga_super_b_level2'] = TextEditingController(
      text: formatPrice(product['harga_super_b_level2'] ?? '0'),
    );
    controllers['harga_super_b_level3'] = TextEditingController(
      text: formatPrice(product['harga_super_b_level3'] ?? '0'),
    );

    controllers['harga_super_c'] = TextEditingController(
      text: formatPrice(product['harga_super_c']),
    );
    controllers['harga_super_c_level1'] = TextEditingController(
      text: formatPrice(product['harga_super_c_level1'] ?? '0'),
    );
    controllers['harga_super_c_level2'] = TextEditingController(
      text: formatPrice(product['harga_super_c_level2'] ?? '0'),
    );
    controllers['harga_super_c_level3'] = TextEditingController(
      text: formatPrice(product['harga_super_c_level3'] ?? '0'),
    );

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

                // Rijek 1
                _buildPriceLevelInputs(
                  category: 'harga_rijek_1',
                  controllers: controllers,
                  label: 'Harga Rijek 1 (D 10-14)',
                ),

                // Rijek 2
                _buildPriceLevelInputs(
                  category: 'harga_rijek_2',
                  controllers: controllers,
                  label: 'Harga Rijek 2 (D 15-19)',
                ),

                // Standar
                _buildPriceLevelInputs(
                  category: 'harga_standar',
                  controllers: controllers,
                  label: 'Harga Standar (D 20 Up)',
                ),

                // Super A
                _buildPriceLevelInputs(
                  category: 'harga_super_a',
                  controllers: controllers,
                  label: 'Harga Super A Custom',
                ),

                // Super B
                _buildPriceLevelInputs(
                  category: 'harga_super_b',
                  controllers: controllers,
                  label: 'Harga Super B Custom',
                ),

                // Super C
                _buildPriceLevelInputs(
                  category: 'harga_super_c',
                  controllers: controllers,
                  label: 'Harga Super C (D 25 Up)',
                ),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama kayu harus diisi')),
                  );
                  return;
                }

                // Update product data dengan level harga
                final updatedProduct = {
                  'id': product['id'],
                  'nama_kayu': nameController.text,

                  // Rijek 1 dengan level
                  'harga_rijek_1': controllers['harga_rijek_1']!.text,
                  'harga_rijek_1_level1':
                      controllers['harga_rijek_1_level1']!.text,
                  'harga_rijek_1_level2':
                      controllers['harga_rijek_1_level2']!.text,
                  'harga_rijek_1_level3':
                      controllers['harga_rijek_1_level3']!.text,

                  // Rijek 2 dengan level
                  'harga_rijek_2': controllers['harga_rijek_2']!.text,
                  'harga_rijek_2_level1':
                      controllers['harga_rijek_2_level1']!.text,
                  'harga_rijek_2_level2':
                      controllers['harga_rijek_2_level2']!.text,
                  'harga_rijek_2_level3':
                      controllers['harga_rijek_2_level3']!.text,

                  // Standar dengan level
                  'harga_standar': controllers['harga_standar']!.text,
                  'harga_standar_level1':
                      controllers['harga_standar_level1']!.text,
                  'harga_standar_level2':
                      controllers['harga_standar_level2']!.text,
                  'harga_standar_level3':
                      controllers['harga_standar_level3']!.text,

                  // Super A dengan level
                  'harga_super_a': controllers['harga_super_a']!.text,
                  'harga_super_a_level1':
                      controllers['harga_super_a_level1']!.text,
                  'harga_super_a_level2':
                      controllers['harga_super_a_level2']!.text,
                  'harga_super_a_level3':
                      controllers['harga_super_a_level3']!.text,

                  // Super B dengan level
                  'harga_super_b': controllers['harga_super_b']!.text,
                  'harga_super_b_level1':
                      controllers['harga_super_b_level1']!.text,
                  'harga_super_b_level2':
                      controllers['harga_super_b_level2']!.text,
                  'harga_super_b_level3':
                      controllers['harga_super_b_level3']!.text,

                  // Super C dengan level
                  'harga_super_c': controllers['harga_super_c']!.text,
                  'harga_super_c_level1':
                      controllers['harga_super_c_level1']!.text,
                  'harga_super_c_level2':
                      controllers['harga_super_c_level2']!.text,
                  'harga_super_c_level3':
                      controllers['harga_super_c_level3']!.text,
                };

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

    // Initialize controllers with empty values
    controllers['harga_rijek_1'] = TextEditingController();
    controllers['harga_rijek_1_level1'] = TextEditingController();
    controllers['harga_rijek_1_level2'] = TextEditingController();
    controllers['harga_rijek_1_level3'] = TextEditingController();

    controllers['harga_rijek_2'] = TextEditingController();
    controllers['harga_rijek_2_level1'] = TextEditingController();
    controllers['harga_rijek_2_level2'] = TextEditingController();
    controllers['harga_rijek_2_level3'] = TextEditingController();

    controllers['harga_standar'] = TextEditingController();
    controllers['harga_standar_level1'] = TextEditingController();
    controllers['harga_standar_level2'] = TextEditingController();
    controllers['harga_standar_level3'] = TextEditingController();

    controllers['harga_super_a'] = TextEditingController();
    controllers['harga_super_a_level1'] = TextEditingController();
    controllers['harga_super_a_level2'] = TextEditingController();
    controllers['harga_super_a_level3'] = TextEditingController();

    controllers['harga_super_b'] = TextEditingController();
    controllers['harga_super_b_level1'] = TextEditingController();
    controllers['harga_super_b_level2'] = TextEditingController();
    controllers['harga_super_b_level3'] = TextEditingController();

    controllers['harga_super_c'] = TextEditingController();
    controllers['harga_super_c_level1'] = TextEditingController();
    controllers['harga_super_c_level2'] = TextEditingController();
    controllers['harga_super_c_level3'] = TextEditingController();

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

                // Rijek 1
                _buildPriceLevelInputs(
                  category: 'harga_rijek_1',
                  controllers: controllers,
                  label: 'Harga Rijek 1 (D 10-14)',
                ),

                // Rijek 2
                _buildPriceLevelInputs(
                  category: 'harga_rijek_2',
                  controllers: controllers,
                  label: 'Harga Rijek 2 (D 15-19)',
                ),

                // Standar
                _buildPriceLevelInputs(
                  category: 'harga_standar',
                  controllers: controllers,
                  label: 'Harga Standar (D 20 Up)',
                ),

                // Super A
                _buildPriceLevelInputs(
                  category: 'harga_super_a',
                  controllers: controllers,
                  label: 'Harga Super A Custom',
                ),

                // Super B
                _buildPriceLevelInputs(
                  category: 'harga_super_b',
                  controllers: controllers,
                  label: 'Harga Super B Custom',
                ),

                // Super C
                _buildPriceLevelInputs(
                  category: 'harga_super_c',
                  controllers: controllers,
                  label: 'Harga Super C (D 25 Up)',
                ),
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
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama kayu harus diisi')),
                  );
                  return;
                }

                final newProduct = {
                  'nama_kayu': nameController.text,

                  // Rijek 1 dengan level
                  'harga_rijek_1': controllers['harga_rijek_1']!.text,
                  'harga_rijek_1_level1':
                      controllers['harga_rijek_1_level1']!.text,
                  'harga_rijek_1_level2':
                      controllers['harga_rijek_1_level2']!.text,
                  'harga_rijek_1_level3':
                      controllers['harga_rijek_1_level3']!.text,

                  // Rijek 2 dengan level
                  'harga_rijek_2': controllers['harga_rijek_2']!.text,
                  'harga_rijek_2_level1':
                      controllers['harga_rijek_2_level1']!.text,
                  'harga_rijek_2_level2':
                      controllers['harga_rijek_2_level2']!.text,
                  'harga_rijek_2_level3':
                      controllers['harga_rijek_2_level3']!.text,

                  // Standar dengan level
                  'harga_standar': controllers['harga_standar']!.text,
                  'harga_standar_level1':
                      controllers['harga_standar_level1']!.text,
                  'harga_standar_level2':
                      controllers['harga_standar_level2']!.text,
                  'harga_standar_level3':
                      controllers['harga_standar_level3']!.text,

                  // Super A dengan level
                  'harga_super_a': controllers['harga_super_a']!.text,
                  'harga_super_a_level1':
                      controllers['harga_super_a_level1']!.text,
                  'harga_super_a_level2':
                      controllers['harga_super_a_level2']!.text,
                  'harga_super_a_level3':
                      controllers['harga_super_a_level3']!.text,

                  // Super B dengan level
                  'harga_super_b': controllers['harga_super_b']!.text,
                  'harga_super_b_level1':
                      controllers['harga_super_b_level1']!.text,
                  'harga_super_b_level2':
                      controllers['harga_super_b_level2']!.text,
                  'harga_super_b_level3':
                      controllers['harga_super_b_level3']!.text,

                  // Super C dengan level
                  'harga_super_c': controllers['harga_super_c']!.text,
                  'harga_super_c_level1':
                      controllers['harga_super_c_level1']!.text,
                  'harga_super_c_level2':
                      controllers['harga_super_c_level2']!.text,
                  'harga_super_c_level3':
                      controllers['harga_super_c_level3']!.text,
                };

                try {
                  await _addProduct(newProduct);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk berhasil ditambah')),
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
        title: Text('Master Harga Beli'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada data harga beli',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddProductDialog,
                    child: Text('Tambah Produk Pertama'),
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
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.forest, color: Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product['nama_kayu'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditProductDialog(product);
                    } else if (value == 'delete') {
                      _showDeleteConfirmationDialog(
                        product['id'],
                        product['nama_kayu'],
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Hapus'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),

            // Harga-harga dengan level
            _buildPriceWithLevels('Rijek 1', product),
            _buildPriceWithLevels('Rijek 2', product),
            _buildPriceWithLevels('Standar', product),
            _buildPriceWithLevels('Super A', product),
            _buildPriceWithLevels('Super B', product),
            _buildPriceWithLevels('Super C', product),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceWithLevels(String category, Map<String, dynamic> product) {
    String basePriceKey =
        'harga_${category.toLowerCase().replaceAll(' ', '_')}';
    String level1Key = '${basePriceKey}_level1';
    String level2Key = '${basePriceKey}_level2';
    String level3Key = '${basePriceKey}_level3';

    String label = priceLabels[basePriceKey] ?? category;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Harga: Rp ${formatPrice(product[basePriceKey])}',
                  style: TextStyle(fontSize: 13, color: Colors.green),
                ),
              ),
              Expanded(
                child: Text(
                  'Lvl 1: Rp ${formatPrice(product[level1Key] ?? 0)}',
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lvl 2: Rp ${formatPrice(product[level2Key] ?? 0)}',
                  style: TextStyle(fontSize: 13, color: Colors.orange),
                ),
              ),
              Expanded(
                child: Text(
                  'Lvl 3: Rp ${formatPrice(product[level3Key] ?? 0)}',
                  style: TextStyle(fontSize: 13, color: Colors.purple),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
