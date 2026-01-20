// [file name]: laporan_labarugi.dart
// [file content begin]
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/database_service.dart';

class LaporanLabaRugiPage extends StatefulWidget {
  @override
  _LaporanLabaRugiPageState createState() => _LaporanLabaRugiPageState();
}

class _LaporanLabaRugiPageState extends State<LaporanLabaRugiPage> {
  double totalHargaBeliBarangTerjual = 0;
  double totalHargaJualBarangTerjual = 0;
  double totalOperasional = 0;

  bool isLoading = true;
  String errorMessage = '';

  int _selectedFilterIndex = 0; // 0: Harian, 1: Bulanan, 2: Tahunan
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  DateTime? _selectedYear;

  final DatabaseService databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    fetchLabaRugi();
  }

  Future<void> fetchLabaRugi() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final db = await databaseService.database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      // Setup filter berdasarkan jenis laporan
      if (_selectedFilterIndex == 0 && _selectedDate != null) {
        // Mode Harian
        final startDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        final endDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          23,
          59,
          59,
        );
        whereClause = ' WHERE p.created_at BETWEEN ? AND ?';
        whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
      } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
        // Mode Bulanan
        final startDate = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month,
          1,
        );
        final endDate = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month + 1,
          0,
          23,
          59,
          59,
        );
        whereClause = ' WHERE p.created_at BETWEEN ? AND ?';
        whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
      } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
        // Mode Tahunan
        final startDate = DateTime(_selectedYear!.year, 1, 1);
        final endDate = DateTime(_selectedYear!.year, 12, 31, 23, 59, 59);
        whereClause = ' WHERE p.created_at BETWEEN ? AND ?';
        whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
      }

      // Query untuk mendapatkan detail penjualan dengan harga master tertinggi
      final query =
          '''
        SELECT 
          pd.nama_kayu,
          pd.kriteria,
          pd.diameter,
          pd.panjang,
          pd.jumlah,
          pd.volume,
          pd.harga_jual,
          pd.jumlah_harga_jual,
          -- Ambil harga master tertinggi dari harga_beli untuk jenis kayu dan kriteria yang sama
          COALESCE((
            SELECT MAX(
              CASE 
                WHEN pd.kriteria = 'Rijek 1' THEN hb.harga_rijek_1
                WHEN pd.kriteria = 'Rijek 2' THEN hb.harga_rijek_2
                WHEN pd.kriteria = 'Standar' THEN hb.harga_standar
                WHEN pd.kriteria = 'Super A' THEN hb.harga_super_a
                WHEN pd.kriteria = 'Super B' THEN hb.harga_super_b
                WHEN pd.kriteria = 'Super C' THEN hb.harga_super_c
                ELSE hb.harga_standar
              END
            )
            FROM harga_beli hb
            WHERE hb.nama_kayu = pd.nama_kayu
          ), 0) as harga_beli_tertinggi,
          -- Hitung total harga beli untuk barang yang terjual berdasarkan harga master tertinggi
          (pd.volume * COALESCE((
            SELECT MAX(
              CASE 
                WHEN pd.kriteria = 'Rijek 1' THEN hb.harga_rijek_1
                WHEN pd.kriteria = 'Rijek 2' THEN hb.harga_rijek_2
                WHEN pd.kriteria = 'Standar' THEN hb.harga_standar
                WHEN pd.kriteria = 'Super A' THEN hb.harga_super_a
                WHEN pd.kriteria = 'Super B' THEN hb.harga_super_b
                WHEN pd.kriteria = 'Super C' THEN hb.harga_super_c
                ELSE hb.harga_standar
              END
            )
            FROM harga_beli hb
            WHERE hb.nama_kayu = pd.nama_kayu
          ), 0)) as total_harga_beli_tertinggi
        FROM penjualan_detail pd
        INNER JOIN penjualan p ON pd.faktur_penj = p.faktur_penj
        $whereClause
        ORDER BY p.created_at DESC
      ''';

      final penjualanDetailList = await db.rawQuery(query, whereArgs);

      // Hitung total harga jual dan total harga beli tertinggi untuk barang yang terjual
      double totalHargaJual = 0;
      double totalHargaBeli = 0;

      for (var item in penjualanDetailList) {
        final hargaJual = (item['jumlah_harga_jual'] as int?)?.toDouble() ?? 0;
        final hargaBeli =
            (item['total_harga_beli_tertinggi'] as num?)?.toDouble() ?? 0;

        totalHargaJual += hargaJual;
        totalHargaBeli += hargaBeli;
      }

      // Hitung biaya operasional dari tabel biaya_lain untuk periode yang sama
      double operasional = 0;

      if (_selectedFilterIndex == 0 && _selectedDate != null) {
        // Mode Harian - ambil biaya_lain untuk tanggal tertentu
        final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final biayaLainList = await db.query(
          'biaya_lain',
          where: 'tanggal = ?',
          whereArgs: [selectedDate],
        );

        for (var biaya in biayaLainList) {
          operasional += (biaya['jumlah_biaya'] as int?)?.toDouble() ?? 0;
        }
      } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
        // Mode Bulanan - ambil biaya_lain untuk bulan tertentu
        final bulan = _selectedMonth!.month;
        final tahun = _selectedMonth!.year;
        final biayaLainList = await databaseService.getBiayaLainByBulanTahun(
          bulan,
          tahun,
        );

        for (var biaya in biayaLainList) {
          operasional += (biaya['jumlah_biaya'] as int?)?.toDouble() ?? 0;
        }
      } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
        // Mode Tahunan - ambil biaya_lain untuk tahun tertentu
        final tahun = _selectedYear!.year;
        final biayaLainList = await db.rawQuery(
          '''
          SELECT * FROM biaya_lain 
          WHERE strftime("%Y", tanggal) = ?
          ORDER BY tanggal DESC
          ''',
          [tahun.toString()],
        );

        for (var biaya in biayaLainList) {
          operasional += (biaya['jumlah_biaya'] as int?)?.toDouble() ?? 0;
        }
      }

      setState(() {
        totalHargaJualBarangTerjual = totalHargaJual;
        totalHargaBeliBarangTerjual = totalHargaBeli;
        totalOperasional = operasional;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      fetchLabaRugi();
    }
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final currentYear = now.year;

    final List<String> bulanList = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Bulan'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthName = bulanList[index];
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _selectedMonth?.month == month &&
                          _selectedMonth?.year == currentYear
                      ? Colors.blue[100]
                      : null,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(currentYear, month, 1);
                  });
                  Navigator.of(context).pop();
                  fetchLabaRugi();
                },
                child: Text(
                  monthName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _pickYear() async {
    final current = _selectedYear?.year ?? DateTime.now().year;
    int sel = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pilih Tahun'),
        content: SizedBox(
          width: double.maxFinite,
          child: YearPicker(
            firstDate: DateTime(2022),
            lastDate: DateTime(DateTime.now().year + 5),
            initialDate: DateTime(current),
            selectedDate: DateTime(sel),
            onChanged: (d) {
              sel = d.year;
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
    setState(() => _selectedYear = DateTime(sel));
    fetchLabaRugi();
  }

  void _resetFilters() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedMonth = null;
      _selectedYear = null;
    });
    fetchLabaRugi();
  }

  Widget _buildFilterTab(String title, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedFilterIndex = index;
            });
            fetchLabaRugi();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    if (_selectedFilterIndex == 0) {
      // Harian
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                        : 'Pilih Tanggal',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_selectedFilterIndex == 1) {
      // Bulanan
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickMonth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedMonth != null
                        ? '${_getBulanName(_selectedMonth!.month)} ${_selectedMonth!.year}'
                        : 'Pilih Bulan',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Tahunan
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _pickYear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(color: Colors.grey),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedYear != null
                        ? DateFormat('yyyy').format(_selectedYear!)
                        : 'Pilih Tahun',
                    style: TextStyle(fontSize: 14),
                  ),
                  Icon(Icons.calendar_today, size: 18),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  String _getBulanName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  void onPrint() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Fitur print belum tersedia")));
  }

  void onSharePDF() async {
    final pdf = pw.Document();

    final labaKotor = totalHargaJualBarangTerjual - totalHargaBeliBarangTerjual;
    final labaBersih = labaKotor - totalOperasional;

    String modeText = "";
    String dateText = "";

    if (_selectedFilterIndex == 0 && _selectedDate != null) {
      modeText = "Harian";
      dateText = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
      modeText = "Bulanan";
      dateText = DateFormat('yyyy-MM').format(_selectedMonth!);
    } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
      modeText = "Tahunan";
      dateText = DateFormat('yyyy').format(_selectedYear!);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan Laba Rugi', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text('Mode: $modeText'),
              pw.Text('Periode: $dateText'),
              pw.Divider(),
              pw.Text(
                'Penjualan: ${currencyFormatter.format(totalHargaJualBarangTerjual)}',
              ),
              pw.Text(
                'Harga Beli Barang Terjual (Harga Master Tertinggi): ${currencyFormatter.format(totalHargaBeliBarangTerjual)}',
              ),
              pw.Text('Laba Kotor: ${currencyFormatter.format(labaKotor)}'),
              pw.Text(
                'Biaya Operasional: ${currencyFormatter.format(totalOperasional)}',
              ),
              pw.Divider(),
              pw.Text(
                'Laba Bersih: ${currencyFormatter.format(labaBersih)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/laporan_laba_rugi.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareFiles([file.path], text: 'Laporan Laba Rugi');
  }

  void onSendWhatsApp() async {
    final labaKotor = totalHargaJualBarangTerjual - totalHargaBeliBarangTerjual;
    final labaBersih = labaKotor - totalOperasional;

    String modeText = "";
    String dateText = "";

    if (_selectedFilterIndex == 0 && _selectedDate != null) {
      modeText = "Harian";
      dateText = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    } else if (_selectedFilterIndex == 1 && _selectedMonth != null) {
      modeText = "Bulanan";
      dateText = DateFormat('yyyy-MM').format(_selectedMonth!);
    } else if (_selectedFilterIndex == 2 && _selectedYear != null) {
      modeText = "Tahunan";
      dateText = DateFormat('yyyy').format(_selectedYear!);
    }

    final message =
        '''Laporan Laba Rugi ($modeText - $dateText)
Penjualan: ${currencyFormatter.format(totalHargaJualBarangTerjual)}
Harga Beli Barang Terjual (Harga Master Tertinggi): ${currencyFormatter.format(totalHargaBeliBarangTerjual)}
Laba Kotor: ${currencyFormatter.format(labaKotor)}
Biaya Operasional: ${currencyFormatter.format(totalOperasional)}
Laba Bersih: ${currencyFormatter.format(labaBersih)}
''';

    final url = Uri.encodeFull('https://wa.me/?text=$message');
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tidak bisa membuka WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final labaKotor = totalHargaJualBarangTerjual - totalHargaBeliBarangTerjual;
    final labaBersih = labaKotor - totalOperasional;

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Laba Rugi'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchLabaRugi,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Menu Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterTab('Harian', 0),
                _buildFilterTab('Bulanan', 1),
                _buildFilterTab('Tahunan', 2),
              ],
            ),
          ),

          // Konten Filter berdasarkan pilihan
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildFilterContent(),
          ),

          // Tombol Reset Filter
          if (_selectedDate != null ||
              _selectedMonth != null ||
              _selectedYear != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextButton(
                onPressed: _resetFilters,
                child: Text('Reset Filter'),
              ),
            ),

          // Garis pemisah
          Divider(height: 1),

          // Data Laporan
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      children: [
                        LaporanItem(
                          label: 'Total Penjualan',
                          value: currencyFormatter.format(
                            totalHargaJualBarangTerjual,
                          ),
                        ),
                        Divider(),
                        LaporanItem(
                          label:
                              'Harga Beli Barang Terjual\n(Harga Master Tertinggi)',
                          value: currencyFormatter.format(
                            totalHargaBeliBarangTerjual,
                          ),
                        ),
                        LaporanItem(
                          label: 'Laba Kotor',
                          value: currencyFormatter.format(labaKotor),
                          valueColor: labaKotor >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                        LaporanItem(
                          label: 'Biaya Operasional',
                          value: currencyFormatter.format(totalOperasional),
                        ),
                        Divider(thickness: 2),
                        LaporanItem(
                          label: 'Laba Bersih',
                          value: currencyFormatter.format(labaBersih),
                          isBold: true,
                          valueColor: labaBersih >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                  ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: onPrint,
                  icon: Icon(Icons.print, color: Colors.white),
                  label: Text('Print', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: onSharePDF,
                  icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text('PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: onSendWhatsApp,
                  icon: Icon(Icons.share, color: Colors.white),
                  label: Text('WA', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LaporanItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const LaporanItem({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          )
        : TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
// [file content end]