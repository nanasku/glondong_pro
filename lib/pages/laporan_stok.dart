import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart'; // Import DatabaseService

class LaporanStokPage extends StatefulWidget {
  const LaporanStokPage({Key? key}) : super(key: key);

  @override
  State<LaporanStokPage> createState() => _LaporanStokPageState();
}

class _LaporanStokPageState extends State<LaporanStokPage> {
  String? _selectedNamaKayu;
  final Map<String, TextEditingController> opnameControllers = {};
  final Map<String, TextEditingController> rusakControllers = {};

  final Map<String, bool> _selectedKriteria = {
    'Rijek 1': false,
    'Rijek 2': false,
    'Standar': false,
    'Super A': false,
    'Super B': false,
    'Super C': false,
    'Rusak': false,
  };

  List<String> namaKayuList = [];
  final DatabaseService databaseService = DatabaseService();

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<StokData> stokList = [];
  bool isLoading = false;
  bool showStokOpnameModal = false;
  bool isLoadingNamaKayu = false;

  @override
  void initState() {
    super.initState();
    _loadNamaKayuList();
  }

  // METHOD UNTUK LOAD NAMA KAYU DARI DATABASE LOKAL
  Future<void> _loadNamaKayuList() async {
    setState(() {
      isLoadingNamaKayu = true;
    });

    try {
      final db = await databaseService.database;

      // Ambil nama kayu unik dari tabel stok
      final result = await db.rawQuery('''
        SELECT DISTINCT nama_kayu FROM stok 
        ORDER BY nama_kayu ASC
      ''');

      // Jika tidak ada data di stok, coba dari pembelian_detail
      if (result.isEmpty) {
        final resultPembelian = await db.rawQuery('''
          SELECT DISTINCT nama_kayu FROM pembelian_detail 
          ORDER BY nama_kayu ASC
        ''');

        setState(() {
          namaKayuList = resultPembelian
              .map((item) => item['nama_kayu'].toString())
              .toList();
          isLoadingNamaKayu = false;
        });
      } else {
        setState(() {
          namaKayuList = result
              .map((item) => item['nama_kayu'].toString())
              .toList();
          isLoadingNamaKayu = false;
        });
      }

      print('✅ SUCCESS: Loaded ${namaKayuList.length} nama kayu from database');
      print('📋 Nama kayu list: $namaKayuList');
    } catch (e) {
      print('❌ EXCEPTION: Error loading nama kayu: $e');
      setState(() {
        isLoadingNamaKayu = false;
      });
      // Fallback untuk testing
      setState(() {
        namaKayuList = [
          'Kayu Alba',
          'Kayu Sengon',
          'Kayu Mahoni',
          'Kayu Balsa',
          'Kayu Jati',
        ];
      });
    }
  }

  // CUSTOM SCROLLABLE DROPDOWN WIDGET
  Widget _buildNamaKayuDropdown() {
    return Container(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (!isLoadingNamaKayu && namaKayuList.isNotEmpty) {
                _showNamaKayuSelectionModal();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedNamaKayu ?? 'Pilih Kayu',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedNamaKayu != null
                            ? Colors.black
                            : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MODAL BOTTOM SHEET UNTUK PILIH NAMA KAYU
  void _showNamaKayuSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Nama Kayu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.green[800]),
                  ),
                ],
              ),
            ),

            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama kayu...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    // Bisa ditambahkan fungsi search nanti
                  },
                ),
              ),
            ),

            // LIST NAMA KAYU
            Expanded(
              child: namaKayuList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forest, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Tidak ada data kayu',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: namaKayuList.length,
                      itemBuilder: (context, index) {
                        final kayu = namaKayuList[index];
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedNamaKayu == kayu
                                ? Colors.green[50]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedNamaKayu == kayu
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.forest,
                              color: _selectedNamaKayu == kayu
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: Text(
                              kayu,
                              style: TextStyle(
                                fontWeight: _selectedNamaKayu == kayu
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedNamaKayu == kayu
                                    ? Colors.green[800]
                                    : Colors.black,
                              ),
                            ),
                            trailing: _selectedNamaKayu == kayu
                                ? Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedNamaKayu = kayu;
                                _selectedKriteria.forEach((key, value) {
                                  _selectedKriteria[key] = false;
                                });
                              });
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Dipilih: $kayu'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),

            // FOOTER BUTTON
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: ${namaKayuList.length} jenis kayu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Tutup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    final selectedKriteriaList = _selectedKriteria.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedKriteriaList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pilih minimal satu kriteria')));
      return;
    }

    setState(() {
      isLoading = true;
      stokList = [];
    });

    try {
      final db = await databaseService.database;

      // ALTERNATIF QUERY JIKA DATA stok KOSONG
      final stokQuery =
          '''
      SELECT 
        pd.nama_kayu,
        pd.kriteria,
        pd.diameter,
        pd.panjang,
        
        -- Stok Pembelian
        COALESCE(SUM(pd.jumlah), 0) as stok_pembelian,
        
        -- Stok Penjualan
        COALESCE((
          SELECT SUM(pjd.jumlah) 
          FROM penjualan_detail pjd 
          WHERE pjd.nama_kayu = pd.nama_kayu 
          AND pjd.kriteria = pd.kriteria 
          AND pjd.diameter = pd.diameter 
          AND pjd.panjang = pd.panjang
        ), 0) as stok_penjualan,
        
        -- Stok Akhir (Pembelian - Penjualan)
        COALESCE(SUM(pd.jumlah), 0) - COALESCE((
          SELECT SUM(pjd.jumlah) 
          FROM penjualan_detail pjd 
          WHERE pjd.nama_kayu = pd.nama_kayu 
          AND pjd.kriteria = pd.kriteria 
          AND pjd.diameter = pd.diameter 
          AND pjd.panjang = pd.panjang
        ), 0) as stok_akhir,
        
        -- Stok Rusak
        COALESCE((
          SELECT SUM(so.stok_rusak) 
          FROM stok_opname so 
          WHERE so.nama_kayu = pd.nama_kayu 
          AND so.kriteria = pd.kriteria 
          AND so.diameter = pd.diameter 
          AND so.panjang = pd.panjang
        ), 0) as stok_rusak,
        
        -- Total Volume
        COALESCE(SUM(pd.volume), 0) - COALESCE((
          SELECT SUM(pjd.volume) 
          FROM penjualan_detail pjd 
          WHERE pjd.nama_kayu = pd.nama_kayu 
          AND pjd.kriteria = pd.kriteria 
          AND pjd.diameter = pd.diameter 
          AND pjd.panjang = pd.panjang
        ), 0) as total_volume
        
      FROM pembelian_detail pd 
      WHERE pd.nama_kayu = ?
      AND pd.kriteria IN (${selectedKriteriaList.map((_) => '?').join(',')})
      GROUP BY pd.nama_kayu, pd.kriteria, pd.diameter, pd.panjang
      ORDER BY pd.kriteria, pd.diameter, pd.panjang
    ''';

      final stokResult = await db.rawQuery(stokQuery, [
        _selectedNamaKayu,
        ...selectedKriteriaList,
      ]);

      print('Stok data from database: $stokResult');

      final List<StokData> loadedData = stokResult
          .map(
            (item) => StokData(
              kriteria: item['kriteria']?.toString() ?? '',
              namaKayu: item['nama_kayu']?.toString() ?? '',
              diameter: int.tryParse(item['diameter']?.toString() ?? '') ?? 0,
              panjang: int.tryParse(item['panjang']?.toString() ?? '') ?? 0,
              stokAwal: 0, // Tidak tersedia di database lokal
              stokPembelian:
                  int.tryParse(item['stok_pembelian']?.toString() ?? '') ?? 0,
              stokPenjualan:
                  int.tryParse(item['stok_penjualan']?.toString() ?? '') ?? 0,
              stokRusak:
                  int.tryParse(item['stok_rusak']?.toString() ?? '') ?? 0,
              stokAkhir:
                  int.tryParse(item['stok_akhir']?.toString() ?? '') ?? 0,
              totalVolume:
                  double.tryParse(item['total_volume']?.toString() ?? '') ??
                  0.0,
            ),
          )
          .toList();

      setState(() {
        stokList = loadedData;
        isLoading = false;
      });

      print('Loaded ${loadedData.length} items from database');
    } catch (e) {
      print('Error details: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  Future<void> _generatePDF() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'LAPORAN STOK KAYU - $_selectedNamaKayu',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 8);

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Kriteria';
    headerRow.cells[1].value = 'Diameter';
    headerRow.cells[2].value = 'Panjang';
    headerRow.cells[3].value = 'Stok Pembelian';
    headerRow.cells[4].value = 'Stok Terjual';
    headerRow.cells[5].value = 'Stok Rusak';
    headerRow.cells[6].value = 'Stok Akhir';
    headerRow.cells[7].value = 'Total Volume';

    for (final stok in stokList) {
      final PdfGridRow row = grid.rows.add();
      row.cells[0].value = stok.kriteria;
      row.cells[1].value = stok.diameter.toString();
      row.cells[2].value = stok.panjang.toString();
      row.cells[3].value = stok.stokPembelian.toString();
      row.cells[4].value = stok.stokPenjualan.toString();
      row.cells[5].value = stok.stokRusak.toString();
      row.cells[6].value = stok.stokAkhir.toString();
      row.cells[7].value = '${stok.totalVolume} cm³';
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(20, 120, page.getClientSize().width - 40, 0),
    );

    final List<int> bytes = await document.save();
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath =
        '${directory.path}/laporan_stok_${_selectedNamaKayu?.toLowerCase().replaceAll(' ', '_')}.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await OpenFile.open(file.path);
  }

  Future<void> _shareWhatsApp() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName =
        'laporan_stok_${_selectedNamaKayu?.toLowerCase().replaceAll(' ', '_')}.pdf';
    final File file = File('$path/$fileName');

    if (!await file.exists()) {
      await _generatePDF();
    }

    final XFile xFile = XFile(file.path);
    await Share.shareXFiles([
      xFile,
    ], text: 'Laporan Stok Kayu - $_selectedNamaKayu');
  }

  Future<void> _generateStokOpnamePDF(List<dynamic> data) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'LAPORAN STOK OPNAME - $_selectedNamaKayu',
      titleFont,
      bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // Tambahkan tanggal
    final PdfFont dateFont = PdfStandardFont(PdfFontFamily.helvetica, 12);
    graphics.drawString(
      'Tanggal: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
      dateFont,
      bounds: Rect.fromLTWH(0, 50, page.getClientSize().width, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 7);

    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'Kriteria';
    headerRow.cells[1].value = 'Diameter (cm)';
    headerRow.cells[2].value = 'Panjang (cm)';
    headerRow.cells[3].value = 'Stok Buku';
    headerRow.cells[4].value = 'Stok Opname';
    headerRow.cells[5].value = 'Stok Rusak';
    headerRow.cells[6].value = 'Selisih';

    for (var item in data) {
      final kriteria = item['kriteria'].toString();
      final diameter = item['diameter'].toString();
      final panjang = item['panjang'].toString();
      // PERBAIKAN: Handle null safety dengan benar
      final stokBuku = int.tryParse(item['stok_akhir']?.toString() ?? '0') ?? 0;

      final uniqueKey = '$kriteria-$diameter-$panjang';
      final opname =
          int.tryParse(opnameControllers[uniqueKey]?.text ?? '') ?? 0;
      final rusak = int.tryParse(rusakControllers[uniqueKey]?.text ?? '') ?? 0;
      final selisih = opname + rusak - stokBuku;

      final row = grid.rows.add();
      row.cells[0].value = kriteria;
      row.cells[1].value = diameter;
      row.cells[2].value = panjang;
      row.cells[3].value = stokBuku.toString();
      row.cells[4].value = opname.toString();
      row.cells[5].value = rusak.toString();
      row.cells[6].value = selisih.toString();
    }

    grid.draw(
      page: page,
      bounds: Rect.fromLTWH(20, 80, page.getClientSize().width - 40, 0),
    );

    final List<int> bytes = await document.save();
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/stok_opname_${_selectedNamaKayu!.toLowerCase().replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Stok Opname - $_selectedNamaKayu');
  }

  void _showStokOpnameModal() async {
    if (_selectedNamaKayu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih nama kayu terlebih dahulu')),
      );
      return;
    }

    try {
      final db = await databaseService.database;

      // GUNAKAN QUERY YANG SAMA DENGAN LAPORAN STOK UNTUK MENDAPATKAN STOK_AKHIR
      final result = await db.rawQuery(
        '''
      SELECT 
        pd.nama_kayu,
        pd.kriteria,
        pd.diameter,
        pd.panjang,
        
        -- Stok Pembelian
        COALESCE(SUM(pd.jumlah), 0) as stok_pembelian,
        
        -- Stok Penjualan
        COALESCE((
          SELECT SUM(pjd.jumlah) 
          FROM penjualan_detail pjd 
          WHERE pjd.nama_kayu = pd.nama_kayu 
          AND pjd.kriteria = pd.kriteria 
          AND pjd.diameter = pd.diameter 
          AND pjd.panjang = pd.panjang
        ), 0) as stok_penjualan,
        
        -- Stok Akhir (Pembelian - Penjualan) - INI YANG DITAMPILKAN SEBAGAI "BUKU"
        COALESCE(SUM(pd.jumlah), 0) - COALESCE((
          SELECT SUM(pjd.jumlah) 
          FROM penjualan_detail pjd 
          WHERE pjd.nama_kayu = pd.nama_kayu 
          AND pjd.kriteria = pd.kriteria 
          AND pjd.diameter = pd.diameter 
          AND pjd.panjang = pd.panjang
        ), 0) as stok_akhir,
        
        -- Stok Rusak
        COALESCE((
          SELECT SUM(so.stok_rusak) 
          FROM stok_opname so 
          WHERE so.nama_kayu = pd.nama_kayu 
          AND so.kriteria = pd.kriteria 
          AND so.diameter = pd.diameter 
          AND so.panjang = pd.panjang
        ), 0) as stok_rusak
        
      FROM pembelian_detail pd 
      WHERE pd.nama_kayu = ?
      AND pd.kriteria IN (
        'Rijek 1', 'Rijek 2', 'Standar', 'Super A', 'Super B', 'Super C', 'Rusak'
      )
      GROUP BY pd.nama_kayu, pd.kriteria, pd.diameter, pd.panjang
      HAVING stok_akhir > 0  -- Hanya tampilkan yang ada stoknya
      ORDER BY pd.kriteria, pd.diameter, pd.panjang
      ''',
        [_selectedNamaKayu],
      );

      // JIKA TIDAK ADA DATA DARI QUERY DI ATAS, COBA DARI TABEL stok
      if (result.isEmpty) {
        final stokResult = await db.rawQuery(
          '''
        SELECT * FROM stok 
        WHERE nama_kayu = ? AND stok_buku > 0
        ORDER BY kriteria, diameter, panjang
        ''',
          [_selectedNamaKayu],
        );

        if (stokResult.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak ada data stok untuk kayu ini')),
          );
          return;
        }

        // Konversi data dari tabel stok ke format yang sama
        for (var item in stokResult) {
          result.add({
            'nama_kayu': item['nama_kayu'],
            'kriteria': item['kriteria'],
            'diameter': item['diameter'],
            'panjang': item['panjang'],
            'stok_akhir':
                item['stok_buku'], // Gunakan stok_buku sebagai stok_akhir
            'stok_pembelian': 0,
            'stok_penjualan': 0,
            'stok_rusak': 0,
          });
        }
      }

      if (result.isNotEmpty) {
        // INISIALISASI CONTROLLERS SEBELUM MENAMPILKAN DIALOG
        for (var item in result) {
          final kriteria = item['kriteria'].toString();
          final diameter = item['diameter'].toString();
          final panjang = item['panjang'].toString();
          final uniqueKey = '$kriteria-$diameter-$panjang';

          // Hanya buat controller baru jika belum ada
          if (!opnameControllers.containsKey(uniqueKey)) {
            opnameControllers[uniqueKey] = TextEditingController();
          }
          if (!rusakControllers.containsKey(uniqueKey)) {
            rusakControllers[uniqueKey] = TextEditingController();
          }
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stok Opname - $_selectedNamaKayu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            opnameControllers.clear();
                            rusakControllers.clear();
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),

                    // INFO
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Stok Opname',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Stok Rusak akan mengurangi Stok Akhir',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[800],
                            ),
                          ),
                          Text(
                            '• Stok Akhir Baru = Stok Buku - Stok Rusak',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TABEL
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 12,
                            horizontalMargin: 8,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 60,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Grade',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: false,
                              ),
                              DataColumn(
                                label: Text(
                                  'D (cm)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'P (cm)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Stok Buku',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Stok Opname',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Stok Rusak',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Selisih',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Stok Akhir Baru',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                            ],
                            rows: result.map((item) {
                              final kriteria = item['kriteria'].toString();
                              final diameter = item['diameter'].toString();
                              final panjang = item['panjang'].toString();
                              final stokBuku =
                                  int.tryParse(
                                    item['stok_akhir']?.toString() ?? '0',
                                  ) ??
                                  0;

                              final uniqueKey = '$kriteria-$diameter-$panjang';

                              final opnameController =
                                  opnameControllers[uniqueKey] ??
                                  TextEditingController();
                              final rusakController =
                                  rusakControllers[uniqueKey] ??
                                  TextEditingController();

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 60),
                                      child: Text(kriteria),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 40),
                                      child: Text(diameter),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 40),
                                      child: Text(panjang),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 40),
                                      child: Text(
                                        stokBuku.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: stokBuku < 10
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 50),
                                      child: TextField(
                                        controller: opnameController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: '0',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          // Trigger rebuild untuk selisih dan stok akhir baru
                                          (context as Element).markNeedsBuild();
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 50),
                                      child: TextField(
                                        controller: rusakController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: '0',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          isDense: true,
                                        ),
                                        onChanged: (value) {
                                          // Trigger rebuild untuk selisih dan stok akhir baru
                                          (context as Element).markNeedsBuild();
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 50),
                                      child: Builder(
                                        builder: (context) {
                                          final opname =
                                              int.tryParse(
                                                opnameController.text,
                                              ) ??
                                              0;
                                          final rusak =
                                              int.tryParse(
                                                rusakController.text,
                                              ) ??
                                              0;
                                          final selisih =
                                              (opname + rusak) - stokBuku;

                                          return Text(
                                            selisih.toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: selisih == 0
                                                  ? Colors.green
                                                  : selisih > 0
                                                  ? Colors.blue
                                                  : Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(minWidth: 50),
                                      child: Builder(
                                        builder: (context) {
                                          final opname =
                                              int.tryParse(
                                                opnameController.text,
                                              ) ??
                                              0;
                                          final rusak =
                                              int.tryParse(
                                                rusakController.text,
                                              ) ??
                                              0;
                                          // STOK AKHIR BARU = Stok Buku - Stok Rusak
                                          final stokAkhirBaru =
                                              stokBuku - rusak;

                                          return Text(
                                            stokAkhirBaru.toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: stokAkhirBaru < 0
                                                  ? Colors.red
                                                  : stokAkhirBaru == stokBuku
                                                  ? Colors.black
                                                  : Colors.orange,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // TOMBOL AKSI
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                opnameControllers.clear();
                                rusakControllers.clear();
                                Navigator.pop(context);
                              },
                              child: Text('Batal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                bool hasError = false;
                                String errorMessage = '';

                                for (var item in result) {
                                  final kriteria = item['kriteria'].toString();
                                  final diameter = item['diameter'].toString();
                                  final panjang = item['panjang'].toString();
                                  final stokBuku =
                                      int.tryParse(
                                        item['stok_akhir']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  final uniqueKey =
                                      '$kriteria-$diameter-$panjang';

                                  final opname =
                                      int.tryParse(
                                        opnameControllers[uniqueKey]?.text ??
                                            '',
                                      ) ??
                                      0;
                                  final rusak =
                                      int.tryParse(
                                        rusakControllers[uniqueKey]?.text ?? '',
                                      ) ??
                                      0;

                                  // Validasi: Stok rusak tidak boleh melebihi stok buku
                                  if (rusak > stokBuku) {
                                    hasError = true;
                                    errorMessage =
                                        'Stok Rusak ($rusak) tidak boleh melebihi Stok Buku ($stokBuku) untuk $kriteria ($diameter x $panjang)';
                                    break;
                                  }

                                  // Validasi: Stok opname + stok rusak tidak boleh melebihi stok buku
                                  if (opname + rusak > stokBuku) {
                                    hasError = true;
                                    errorMessage =
                                        'Jumlah Stok Opname ($opname) + Stok Rusak ($rusak) tidak boleh melebihi Stok Buku ($stokBuku) untuk $kriteria ($diameter x $panjang)';
                                    break;
                                  }

                                  if (opname < 0 || rusak < 0) {
                                    hasError = true;
                                    errorMessage =
                                        'Input tidak boleh negatif untuk $kriteria ($diameter x $panjang)';
                                    break;
                                  }
                                }

                                if (hasError) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMessage),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Simpan ke database stok_opname DAN update stok di tabel stok
                                for (var item in result) {
                                  final kriteria = item['kriteria'].toString();
                                  final diameter = item['diameter'].toString();
                                  final panjang = item['panjang'].toString();
                                  final stokBuku =
                                      int.tryParse(
                                        item['stok_akhir']?.toString() ?? '0',
                                      ) ??
                                      0;
                                  final uniqueKey =
                                      '$kriteria-$diameter-$panjang';

                                  final opname =
                                      int.tryParse(
                                        opnameControllers[uniqueKey]?.text ??
                                            '',
                                      ) ??
                                      0;
                                  final rusak =
                                      int.tryParse(
                                        rusakControllers[uniqueKey]?.text ?? '',
                                      ) ??
                                      0;

                                  // Hitung stok akhir baru
                                  final stokAkhirBaru = stokBuku - rusak;

                                  // 1. Simpan ke tabel stok_opname
                                  final opnameData = {
                                    "nama_kayu": item['nama_kayu'],
                                    "kriteria": kriteria,
                                    "diameter": item['diameter'],
                                    "panjang": item['panjang'],
                                    "stok_buku": stokBuku,
                                    "stok_opname": opname,
                                    "stok_rusak": rusak,
                                    "selisih": (opname + rusak - stokBuku),
                                    "tanggal_opname": DateFormat(
                                      "yyyy-MM-dd",
                                    ).format(DateTime.now()),
                                    "keterangan": "Input via mobile",
                                  };

                                  await db.insert('stok_opname', opnameData);

                                  // 2. UPDATE STOK DI TABEL stok (stok_buku dikurangi stok rusak)
                                  final existingStok = await db.query(
                                    'stok',
                                    where:
                                        'nama_kayu = ? AND kriteria = ? AND diameter = ? AND panjang = ?',
                                    whereArgs: [
                                      item['nama_kayu'],
                                      kriteria,
                                      diameter,
                                      panjang,
                                    ],
                                  );

                                  if (existingStok.isNotEmpty) {
                                    // Update stok yang sudah ada
                                    await db.update(
                                      'stok',
                                      {
                                        'stok_buku': stokAkhirBaru,
                                        'updated_at': DateFormat(
                                          "yyyy-MM-dd HH:mm:ss",
                                        ).format(DateTime.now()),
                                      },
                                      where:
                                          'nama_kayu = ? AND kriteria = ? AND diameter = ? AND panjang = ?',
                                      whereArgs: [
                                        item['nama_kayu'],
                                        kriteria,
                                        diameter,
                                        panjang,
                                      ],
                                    );
                                  } else {
                                    // Insert stok baru jika belum ada
                                    await db.insert('stok', {
                                      'nama_kayu': item['nama_kayu'],
                                      'kriteria': kriteria,
                                      'diameter': diameter,
                                      'panjang': panjang,
                                      'stok_buku': stokAkhirBaru,
                                      'created_at': DateFormat(
                                        "yyyy-MM-dd HH:mm:ss",
                                      ).format(DateTime.now()),
                                      'updated_at': DateFormat(
                                        "yyyy-MM-dd HH:mm:ss",
                                      ).format(DateTime.now()),
                                    });
                                  }
                                }

                                opnameControllers.clear();
                                rusakControllers.clear();

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Stok opname berhasil disimpan dan stok diperbarui',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );

                                // Refresh data laporan stok
                                _loadData();
                              },
                              child: Text('Simpan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _generateStokOpnamePDF(result);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share, size: 16),
                                  SizedBox(width: 4),
                                  Text('WA'),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      print('Error stok opname: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok Kayu'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Nama Kayu dan Kriteria
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Pilih Nama Kayu:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      isLoadingNamaKayu
                          ? Container(
                              width: 200,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : _buildNamaKayuDropdown(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Kriteria:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedKriteria.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        selectedColor: Colors.green[100],
                        checkmarkColor: Colors.green,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedKriteria[entry.key] = selected;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text('Tampilkan Data'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _showStokOpnameModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text('Stok Opname'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabel Data
            Container(
              padding: const EdgeInsets.all(8),
              child: isLoading
                  ? Container(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : stokList.isEmpty
                  ? Container(
                      height: 200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada data stok',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            if (_selectedNamaKayu != null)
                              Text(
                                'Pilih kriteria dan klik "Tampilkan Data"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Grade')),
                            DataColumn(label: Text('D (cm)')),
                            DataColumn(label: Text('P (cm)')),
                            DataColumn(label: Text('Stok Beli')),
                            DataColumn(label: Text('Stok Jual')),
                            DataColumn(label: Text('Stok Rusak')),
                            DataColumn(label: Text('Stok Akhir')),
                            DataColumn(label: Text('Total Volume')),
                          ],
                          rows: stokList.map((stok) {
                            return DataRow(
                              cells: [
                                DataCell(Text(stok.kriteria)),
                                DataCell(Text('${stok.diameter}')),
                                DataCell(Text('${stok.panjang}')),
                                DataCell(Text(stok.stokPembelian.toString())),
                                DataCell(Text(stok.stokPenjualan.toString())),
                                DataCell(Text(stok.stokRusak.toString())),
                                DataCell(
                                  Text(
                                    stok.stokAkhir.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: stok.stokAkhir < 10
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${stok.totalVolume} cm³')),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            // Tombol Aksi
            if (stokList.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _generatePDF,
                      icon: const Icon(Icons.print),
                      label: const Text('Print PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _shareWhatsApp,
                      icon: const Icon(Icons.share),
                      label: const Text('Share WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class StokData {
  final String kriteria;
  final String namaKayu;
  final int diameter;
  final int panjang;
  final int stokAwal;
  final int stokPembelian;
  final int stokPenjualan;
  final int stokRusak;
  final int stokAkhir;
  final double totalVolume; // Ubah dari int ke double

  StokData({
    required this.kriteria,
    required this.namaKayu,
    required this.diameter,
    required this.panjang,
    required this.stokAwal,
    required this.stokPembelian,
    required this.stokPenjualan,
    required this.stokRusak,
    required this.stokAkhir,
    required this.totalVolume, // Sesuaikan dengan perubahan
  });
}
