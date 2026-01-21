import 'package:flutter/material.dart';
import 'package:tpk_app/services/database_service.dart';

class MasterBeliPage extends StatefulWidget {
  const MasterBeliPage({Key? key}) : super(key: key);

  @override
  _MasterBeliPageState createState() => _MasterBeliPageState();
}

class _MasterBeliPageState extends State<MasterBeliPage> {
  // ✅ Labels untuk harga dengan deskripsi singkat
  final Map<String, String> priceLabels = {
    'harga_rijek_1': 'Rijek 1 (D10-14)',
    'harga_rijek_2': 'Rijek 2 (D15-19)',
    'harga_standar': 'Standar (D20 Up)',
    'harga_super_a': 'Super A',
    'harga_super_b': 'Super B',
    'harga_super_c': 'Super C (D25 Up)',
  };

  List<Map<String, dynamic>> products = [];
  Map<int, bool> expandedStates = {}; // Untuk melacak state expand/collapse
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

  // Toggle expand/collapse state
  void _toggleExpand(int id) {
    setState(() {
      expandedStates[id] = !(expandedStates[id] ?? false);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final db = await DatabaseService().database;
      final data = await db.query('harga_beli', orderBy: 'nama_kayu ASC');

      // Inisialisasi semua state collapsed secara default
      final expandedMap = <int, bool>{};
      for (var product in data) {
        expandedMap[product['id'] as int] = false;
      }

      setState(() {
        products = List<Map<String, dynamic>>.from(data);
        expandedStates = expandedMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
      print('Error fetching products: $e');
    }
  }

  // Fungsi untuk menambah produk baru dengan level harga
  Future<void> _addProduct(Map<String, dynamic> newProduct) async {
    try {
      final db = await DatabaseService().database;
      final result = await db.insert('harga_beli', {
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

      // Tambahkan state expand untuk produk baru
      setState(() {
        expandedStates[result] = false;
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

      // Hapus state expand
      setState(() {
        expandedStates.remove(id);
      });

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
            prefixText: '',
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
                  labelText: 'Lv 1',
                  border: OutlineInputBorder(),
                  prefixText: '',
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
                  labelText: 'Lv 2',
                  border: OutlineInputBorder(),
                  prefixText: '',
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
                  labelText: 'Lv 3',
                  border: OutlineInputBorder(),
                  prefixText: '',
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
      text: formatPrice(product['harga_rijek_2_level2'] ?? '0'),
    );
    controllers['harga_rijek_2_level3'] = TextEditingController(
      text: formatPrice(product['harga_rijek_2_level3'] ?? '0'),
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
          title: Text('Edit Harga Kayu'),
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
          title: Text('➕ Kayu Baru'),
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
                    SnackBar(content: Text('Kayu berhasil ditambah')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menambah kayu: $e')),
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
          title: Text('Hapus Kayu'),
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
          : _buildProductList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isExpanded = expandedStates[product['id']] ?? false;
        return _buildExpandableProductCard(product, isExpanded);
      },
    );
  }

  Widget _buildExpandableProductCard(
    Map<String, dynamic> product,
    bool isExpanded,
  ) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          // Header yang bisa di-klik untuk expand/collapse
          InkWell(
            onTap: () => _toggleExpand(product['id']),
            child: Container(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.forest,
                      size: 16,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product['nama_kayu'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Tombol expand/collapse
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  // Tombol edit
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditProductDialog(product),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                  SizedBox(width: 4),
                  // Tombol hapus
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(
                      product['id'],
                      product['nama_kayu'],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            ),
          ),

          // Konten yang bisa di-expand/collapse
          AnimatedCrossFade(
            firstChild: Container(), // Saat collapsed, kosong
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 0.5),
                  SizedBox(height: 8),
                  _buildPriceListForProduct(product),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceListForProduct(Map<String, dynamic> product) {
    // Daftar kategori harga
    final categories = [
      'harga_rijek_1',
      'harga_rijek_2',
      'harga_standar',
      'harga_super_a',
      'harga_super_b',
      'harga_super_c',
    ];

    return Column(
      children: categories.map((category) {
        return _buildPriceItem(category, product);
      }).toList(),
    );
  }

  Widget _buildPriceItem(String category, Map<String, dynamic> product) {
    final basePrice = formatPrice(product[category]);
    final level1Price = formatPrice(product['${category}_level1'] ?? 0);
    final level2Price = formatPrice(product['${category}_level2'] ?? 0);
    final level3Price = formatPrice(product['${category}_level3'] ?? 0);

    final label = priceLabels[category] ?? category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris label dan harga dasar
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ),
            Text(
              'Rp $basePrice',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),

        SizedBox(height: 4),

        // Baris level harga
        Row(
          children: [
            Expanded(
              child: _buildLevelItem('Lv 1', level1Price, Colors.blue[700]!),
            ),
            SizedBox(width: 4),
            Expanded(
              child: _buildLevelItem('Lv 2', level2Price, Colors.orange[700]!),
            ),
            SizedBox(width: 4),
            Expanded(
              child: _buildLevelItem('Lv 3', level3Price, Colors.purple[700]!),
            ),
          ],
        ),

        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLevelItem(String label, String price, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
