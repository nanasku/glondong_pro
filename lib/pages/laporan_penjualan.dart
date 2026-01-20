import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import '../services/database_service.dart'; // Ganti ApiService dengan DatabaseService
import 'package:intl/date_symbol_data_local.dart';

class LaporanPenjualanPage extends StatefulWidget {
  const LaporanPenjualanPage({Key? key}) : super(key: key);

  @override
  State<LaporanPenjualanPage> createState() => _LaporanPenjualanPageState();
}

enum ReportType { transaksi, harian, bulanan, tahunan, pembeli }

class _LaporanPenjualanPageState extends State<LaporanPenjualanPage> {
  ReportType _selected = ReportType.transaksi;
  final DatabaseService databaseService = DatabaseService();

  // Filters
  DateTime? _selectedDate;
  DateTime? _selectedMonth;
  int? _selectedYear;
  String? _selectedFaktur;

  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _singleTransaksi;
  bool _loading = false;

  List<Map<String, dynamic>> _daftarPembeli = [];
  String? _selectedPembeliId;
  String? _selectedPembeliNama;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedMonth = DateTime.now();
    _selectedYear = DateTime.now().year;
    _loadDaftarPembeli();
    _initializeDateFormatting();
  }

  // Tambahkan method ini
  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('id_ID', null);
  }

  // Method untuk load daftar pembeli dari database lokal
  Future<void> _loadDaftarPembeli() async {
    try {
      final pembeliList = await databaseService.getAllPembeli();
      setState(() {
        _daftarPembeli = List<Map<String, dynamic>>.from(pembeliList);
      });
    } catch (e) {
      debugPrint('Error loading daftar pembeli: $e');
      _daftarPembeli = [];
    }
  }

  // Method untuk mengambil data penjualan dari database lokal
  Future<void> _fetchForReport() async {
    setState(() => _loading = true);
    try {
      final db = await databaseService.database;

      String query = '''
        SELECT 
          p.id,
          p.faktur_penj,
          p.created_at,
          p.total,
          penj.nama as nama_pembeli,
          penj.id as pembeli_id
        FROM penjualan p
        LEFT JOIN pembeli penj ON p.pembeli_id = penj.id
        WHERE 1=1
      ''';

      List<dynamic> whereArgs = [];

      // Tambahkan filter berdasarkan jenis laporan
      if (_selected == ReportType.harian && _selectedDate != null) {
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
        query += ' AND p.created_at BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      } else if (_selected == ReportType.bulanan && _selectedMonth != null) {
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
        query += ' AND p.created_at BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      } else if (_selected == ReportType.tahunan && _selectedYear != null) {
        final startDate = DateTime(_selectedYear!, 1, 1);
        final endDate = DateTime(_selectedYear!, 12, 31, 23, 59, 59);
        query += ' AND p.created_at BETWEEN ? AND ?';
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      } else if (_selected == ReportType.pembeli &&
          _selectedPembeliId != null &&
          _selectedPembeliId!.isNotEmpty) {
        query += ' AND p.pembeli_id = ?';
        whereArgs.add(int.tryParse(_selectedPembeliId!) ?? 0);
      } else if (_selected == ReportType.transaksi &&
          _selectedFaktur != null &&
          _selectedFaktur!.isNotEmpty) {
        query += ' AND p.faktur_penj LIKE ?';
        whereArgs.add('%$_selectedFaktur%');
      }

      query += ' ORDER BY p.created_at DESC';

      debugPrint('Query: $query');
      debugPrint('Args: $whereArgs');

      final penjualanList = await db.rawQuery(query, whereArgs);

      // Ambil detail dan operasional untuk setiap penjualan
      final List<Map<String, dynamic>> completeData = [];

      for (var penjualan in penjualanList) {
        // Ambil detail penjualan
        final detailQuery = '''
          SELECT * FROM penjualan_detail 
          WHERE faktur_penj = ?
        ''';
        final details = await db.rawQuery(detailQuery, [
          penjualan['faktur_penj'],
        ]);

        // Ambil operasional penjualan
        final operasionalQuery = '''
          SELECT * FROM penjualan_operasional 
          WHERE faktur_penj = ?
        ''';
        final operasionals = await db.rawQuery(operasionalQuery, [
          penjualan['faktur_penj'],
        ]);

        // Gabungkan data
        completeData.add({
          ...penjualan,
          'detail': details,
          'operasionals': operasionals,
        });
      }

      setState(() {
        _data = completeData;
        if (_selected == ReportType.transaksi &&
            _selectedFaktur != null &&
            _selectedFaktur!.isNotEmpty &&
            _data.isNotEmpty) {
          _singleTransaksi = _data.first;
        } else {
          _singleTransaksi = null;
        }
      });

      debugPrint('Jumlah data ditemukan: ${_data.length}');
    } catch (e) {
      debugPrint('Fetch error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error mengambil data: $e')));
      setState(() {
        _data = [];
        _singleTransaksi = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // Helper methods untuk akses data yang aman
  String? _safeGetString(dynamic data, String key) {
    if (data is Map) {
      final value = data[key];
      return value?.toString();
    }
    return null;
  }

  int _safeGetInt(dynamic data, String key) {
    if (data is Map) {
      final value = data[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
    }
    return 0;
  }

  num _safeGetNum(dynamic data, String key) {
    if (data is Map) {
      final value = data[key];
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Helper untuk menghitung biaya operasional
  num _calculateOperasional(Map<String, dynamic> transaksi) {
    num opsSum = 0;
    final operasionals = transaksi['operasionals'];

    if (operasionals is List) {
      for (var op in operasionals) {
        final safeOp = op is Map ? op : <String, dynamic>{};
        final biaya = _safeGetNum(safeOp, 'biaya');
        final tipe = _safeGetString(safeOp, 'tipe');
        if (tipe == 'tambah') {
          opsSum += biaya;
        } else {
          opsSum -= biaya;
        }
      }
    }

    return opsSum;
  }

  // Utility: group penjualan_detail into report structure
  Map<String, dynamic> _aggregateByKayu(List<dynamic> items) {
    final Map<String, dynamic> res = {};

    for (var transaksi in items) {
      List<dynamic>? details;

      if (transaksi is Map && transaksi.containsKey('detail')) {
        details = transaksi['detail'] is List
            ? List.from(transaksi['detail'])
            : [];
      }

      if (details == null) continue;

      for (var d in details) {
        final dynamicDetail = d;
        final nk = _safeGetString(dynamicDetail, 'nama_kayu') ?? 'Unknown';
        final k = _safeGetString(dynamicDetail, 'kriteria') ?? '-';
        final diam = _safeGetString(dynamicDetail, 'diameter') ?? '-';
        final panjang = _safeGetString(dynamicDetail, 'panjang') ?? '-';
        final jumlah = _safeGetInt(dynamicDetail, 'jumlah');
        final vol = _safeGetNum(dynamicDetail, 'volume');
        final harga = _safeGetNum(dynamicDetail, 'jumlah_harga_jual');

        if (!res.containsKey(nk)) {
          res[nk] = <String, dynamic>{};
        }

        final nkMap = res[nk] as Map<String, dynamic>;
        if (!nkMap.containsKey(k)) {
          nkMap[k] = <Map<String, dynamic>>[];
        }

        final list = nkMap[k] as List<Map<String, dynamic>>;
        list.add({
          'diameter': diam,
          'panjang': panjang,
          'jumlah': jumlah,
          'volume': vol,
          'total': harga,
        });
      }
    }

    return res;
  }

  // Create PDF Report
  Future<File> _createPdfReport() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_selected == ReportType.transaksi && _singleTransaksi != null) {
      final t = _singleTransaksi!;
      final title = 'LAPORAN PENJUALAN TIAP TRANSAKSI';

      pdf.addPage(
        pw.MultiPage(
          build: (ctx) {
            final List<pw.Widget> widgets = [];

            // HEADER
            widgets.add(
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.left,
              ),
            );
            widgets.add(pw.SizedBox(height: 12));

            // INFORMASI TRANSAKSI
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'No. Faktur : ${_safeGetString(t, 'faktur_penj') ?? '-'}',
                  ),
                  pw.Text(
                    'Tanggal    : ${_formatDateTime(_safeGetString(t, 'created_at'))}',
                  ),
                  pw.Text(
                    'Pembeli    : ${_safeGetString(t, 'nama_pembeli') ?? '-'}',
                  ),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 16));

            // DETAIL KAYU
            final agg = _aggregateByKayu([t]);
            int totalSemuaBatang = 0;
            num totalSemuaJmlVol = 0; // GANTI: total Jml Vol keseluruhan
            num totalSemuaHarga = 0;

            agg.forEach((namaKayu, kriteriaMap) {
              final safeKriteriaMap = kriteriaMap is Map
                  ? kriteriaMap
                  : <String, dynamic>{};

              widgets.add(
                pw.Text(
                  'Nama Kayu: $namaKayu',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              );
              widgets.add(pw.SizedBox(height: 8));

              safeKriteriaMap.forEach((kriteria, rows) {
                widgets.add(
                  pw.Text('Grd $kriteria', textAlign: pw.TextAlign.left),
                );
                widgets.add(pw.SizedBox(height: 4));

                final tableRows = <List<pw.Widget>>[];
                tableRows.add([
                  pw.Text('D', textAlign: pw.TextAlign.left),
                  pw.Text('P', textAlign: pw.TextAlign.left),
                  pw.Text('Jml', textAlign: pw.TextAlign.left),
                  pw.Text('Vol', textAlign: pw.TextAlign.left),
                  pw.Text('Jml Vol', textAlign: pw.TextAlign.left),
                  pw.Text('Total', textAlign: pw.TextAlign.left),
                ]);

                int totalJml = 0;
                num totalJmlVol = 0; // GANTI: total Jml Vol per kriteria
                num totalHarga = 0;

                if (rows is List) {
                  for (var r in rows) {
                    final safeRow = r is Map ? r : <String, dynamic>{};
                    final jumlah = (safeRow['jumlah'] as int?) ?? 0;
                    final volume = (safeRow['volume'] as num?) ?? 0;
                    final jmlVol = jumlah * volume; // HITUNG Jml Vol

                    tableRows.add([
                      pw.Text(
                        safeRow['diameter']?.toString() ?? '-',
                        textAlign: pw.TextAlign.left,
                      ),
                      pw.Text(
                        safeRow['panjang']?.toString() ?? '-',
                        textAlign: pw.TextAlign.left,
                      ),
                      pw.Text(jumlah.toString(), textAlign: pw.TextAlign.left),
                      pw.Text(volume.toString(), textAlign: pw.TextAlign.left),
                      pw.Text(jmlVol.toString(), textAlign: pw.TextAlign.left),
                      pw.Text(
                        formatter.format(safeRow['total'] ?? 0),
                        textAlign: pw.TextAlign.left,
                      ),
                    ]);

                    totalJml += jumlah;
                    totalJmlVol += jmlVol; // JUMLAHKAN Jml Vol
                    totalHarga += (safeRow['total'] as num?) ?? 0;
                  }
                }

                widgets.add(
                  pw.Table.fromTextArray(
                    context: ctx,
                    data: tableRows,
                    defaultColumnWidth: pw.FlexColumnWidth(1.0),
                    tableWidth: pw.TableWidth.min,
                  ),
                );
                widgets.add(pw.SizedBox(height: 6));

                // TAMPILKAN TOTAL YANG BENAR
                widgets.add(
                  pw.Text(
                    'Total: Jml $totalJml Jml Vol ${totalJmlVol.toString()} Harga ${formatter.format(totalHarga)}',
                    textAlign: pw.TextAlign.left,
                  ),
                );
                widgets.add(pw.SizedBox(height: 8));

                totalSemuaBatang += totalJml;
                totalSemuaJmlVol +=
                    totalJmlVol; // JUMLAHKAN ke total keseluruhan
                totalSemuaHarga += totalHarga;
              });

              widgets.add(pw.SizedBox(height: 12));
            });

            // Hitung ulang dari details untuk akurasi
            int totalBatangDariDetails = 0;
            num totalJmlVolDariDetails = 0; // GANTI: total Jml Vol dari details
            num totalHargaDariDetails = 0;

            final details = t['detail'] is List ? List.from(t['detail']) : [];
            for (var detail in details) {
              final jumlah = _safeGetInt(detail, 'jumlah');
              final volume = _safeGetNum(detail, 'volume');
              totalBatangDariDetails += jumlah;
              totalJmlVolDariDetails +=
                  jumlah * volume; // HITUNG Jml Vol dari details
              totalHargaDariDetails += _safeGetNum(detail, 'jumlah_harga_jual');
            }

            final int finalTotalBatang = totalBatangDariDetails > 0
                ? totalBatangDariDetails
                : totalSemuaBatang;
            final num finalTotalJmlVol = totalJmlVolDariDetails > 0
                ? totalJmlVolDariDetails
                : totalSemuaJmlVol;
            final num finalTotalHarga = totalHargaDariDetails > 0
                ? totalHargaDariDetails
                : totalSemuaHarga;

            // Hitung operasional
            num opsSum = _calculateOperasional(t);

            // RINGKASAN KESELURUHAN - GUNAKAN TOTAL Jml Vol YANG BENAR
            widgets.add(pw.Divider());
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Jumlah Batang      : $finalTotalBatang'),
                  pw.Text(
                    'Total Jml Vol      : ${finalTotalJmlVol.toString()} cm³',
                  ), // YANG BENAR
                  pw.Text(
                    'Total Harga        : ${formatter.format(finalTotalHarga)}',
                  ),
                  pw.Text('Biaya Operasional  : ${formatter.format(opsSum)}'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Total (Total Akhir) : ${formatter.format(finalTotalHarga + opsSum)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );

            return widgets;
          },
        ),
      );
    } else {
      // LAPORAN HARIAN/BULANAN/TAHUNAN/PEMBELI
      String title = 'LAPORAN PENJUALAN';
      if (_selected == ReportType.harian) title = 'LAPORAN PENJUALAN HARIAN';
      if (_selected == ReportType.bulanan) title = 'LAPORAN PENJUALAN BULANAN';
      if (_selected == ReportType.tahunan) title = 'LAPORAN PENJUALAN TAHUNAN';
      if (_selected == ReportType.pembeli)
        title = 'LAPORAN PENJUALAN BERDASARKAN PEMBELI';

      pdf.addPage(
        pw.MultiPage(
          build: (ctx) {
            final List<pw.Widget> widgets = [];

            // HEADER
            widgets.add(
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.left,
              ),
            );
            widgets.add(pw.SizedBox(height: 12));

            // INFORMASI FILTER
            if (_selected == ReportType.harian && _selectedDate != null) {
              widgets.add(
                pw.Text(
                  'Tanggal : ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  textAlign: pw.TextAlign.left,
                ),
              );
            }
            if (_selected == ReportType.bulanan && _selectedMonth != null) {
              widgets.add(
                pw.Text(
                  'Bulan : ${DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)}',
                  textAlign: pw.TextAlign.left,
                ),
              );
            }
            if (_selected == ReportType.tahunan && _selectedYear != null) {
              widgets.add(
                pw.Text('Tahun : $_selectedYear', textAlign: pw.TextAlign.left),
              );
            }
            if (_selected == ReportType.pembeli) {
              widgets.add(
                pw.Text(
                  'Nama Pembeli : ${_data.isNotEmpty ? _data[0]['nama_pembeli'] ?? '-' : '-'}',
                  textAlign: pw.TextAlign.left,
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 16));

            // TABEL DATA
            final table = <List<pw.Widget>>[];
            table.add([
              pw.Text('No.', textAlign: pw.TextAlign.left),
              pw.Text('Nomor Faktur', textAlign: pw.TextAlign.left),
              pw.Text('Jml', textAlign: pw.TextAlign.left),
              pw.Text('Jml Vol', textAlign: pw.TextAlign.left),
              pw.Text('Total', textAlign: pw.TextAlign.left),
              pw.Text('Operasional', textAlign: pw.TextAlign.left),
              pw.Text('Total Akhir', textAlign: pw.TextAlign.left),
            ]);

            int no = 1;
            int sumJmlBatang = 0;
            num sumVolume = 0;
            num sumTotal = 0;
            num sumOper = 0;

            for (var tx in _data) {
              int jml = 0;
              num vol = 0;
              num tot = 0;
              if (tx['detail'] != null) {
                for (var d in List.from(tx['detail'])) {
                  jml += int.tryParse(d['jumlah'].toString()) ?? 0;
                  vol += num.tryParse(d['volume'].toString()) ?? 0;
                  tot += num.tryParse(d['jumlah_harga_jual'].toString()) ?? 0;
                }
              }

              num ops = _calculateOperasional(tx);

              table.add([
                pw.Text(no.toString(), textAlign: pw.TextAlign.left),
                pw.Text(tx['faktur_penj'] ?? '-', textAlign: pw.TextAlign.left),
                pw.Text(jml.toString(), textAlign: pw.TextAlign.left),
                pw.Text(vol.toString(), textAlign: pw.TextAlign.left),
                pw.Text(formatter.format(tot), textAlign: pw.TextAlign.left),
                pw.Text(formatter.format(ops), textAlign: pw.TextAlign.left),
                pw.Text(
                  formatter.format(tot + ops),
                  textAlign: pw.TextAlign.left,
                ),
              ]);

              sumJmlBatang += jml;
              sumVolume += vol;
              sumTotal += tot;
              sumOper += ops;
              no++;
            }

            widgets.add(
              pw.Table.fromTextArray(
                context: ctx,
                data: table,
                defaultColumnWidth: pw.FlexColumnWidth(1.0),
                tableWidth: pw.TableWidth.min,
              ),
            );
            widgets.add(pw.SizedBox(height: 16));

            // RINGKASAN
            widgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Total ${_data.length} transaksi'),
                  pw.Text('Jumlah Batang      : $sumJmlBatang'),
                  pw.Text('Total Volume       : ${sumVolume.toString()} cm³'),
                  pw.Text('Total Harga        : ${formatter.format(sumTotal)}'),
                  pw.Text('Biaya Operasional  : ${formatter.format(sumOper)}'),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Total (Total Akhir) : ${formatter.format(sumTotal + sumOper)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );

            return widgets;
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/laporan_penjualan${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  // Create Excel Report
  Future<File> _createExcelReport() async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan'];

    sheet.appendRow([
      'No',
      'Nomor Faktur',
      'Jumlah Batang',
      'Volume',
      'Total',
      'Operasional',
      'Total Akhir',
    ]);
    int no = 1;

    for (var tx in _data) {
      int jml = 0;
      num vol = 0;
      num tot = 0;
      if (tx['detail'] != null) {
        for (var d in List.from(tx['detail'])) {
          jml += int.tryParse(d['jumlah'].toString()) ?? 0;
          vol += num.tryParse(d['volume'].toString()) ?? 0;
          tot += num.tryParse(d['jumlah_harga_beli'].toString()) ?? 0;
        }
      }

      num ops = _calculateOperasional(tx);

      sheet.appendRow([
        no,
        tx['faktur_penj'] ?? '-',
        jml,
        vol,
        tot,
        ops,
        tot + ops,
      ]);
      no++;
    }

    final fileBytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/laporan_penjualan_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(fileBytes!);
    return file;
  }

  Future<void> _exportAndShare() async {
    setState(() => _loading = true);
    try {
      final pdfFile = await _createPdfReport();
      final excelFile = await _createExcelReport();

      await Share.shareXFiles([
        XFile(pdfFile.path),
        XFile(excelFile.path),
      ], text: 'Laporan Penjualan');
    } catch (e) {
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // Helper untuk format datetime
  String _formatDateTime(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final currentYear = now.year;

    // Daftar bulan dalam bahasa Indonesia
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

    // Tampilkan dialog pilih bulan
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pilih Bulan'),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
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
                ),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(currentYear, month, 1);
                  });
                  Navigator.of(context).pop();
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickYear() async {
    await initializeDateFormatting('id_ID', null);

    final current = _selectedYear ?? DateTime.now().year;
    int sel = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pilih Tahun'),
        content: SizedBox(
          width: double.maxFinite,
          child: YearPicker(
            firstDate: DateTime(2000),
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
    setState(() => _selectedYear = sel);
  }

  Widget _buildFilterControls() {
    switch (_selected) {
      case ReportType.transaksi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                _selectedFaktur = null;
                _fetchForReport();
              },
              child: Text('Load Semua Transaksi'),
            ),
            SizedBox(height: 12),
            Text('Atau cari berdasarkan nomor faktur:'),
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Contoh: PJ-06102025-0001',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) => _selectedFaktur = v.trim(),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchForReport,
              child: Text('Cari Faktur'),
            ),
            SizedBox(height: 8),
            if (_selectedFaktur != null && _selectedFaktur!.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Mencari: $_selectedFaktur',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        );

      case ReportType.harian:
        return Row(
          children: [
            Text(
              _selectedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                  : '-',
            ),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _pickDate, child: Text('Pilih tanggal')),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _fetchForReport, child: Text('Load')),
          ],
        );

      case ReportType.bulanan:
        return Row(
          children: [
            FutureBuilder(
              future: initializeDateFormatting('id_ID', null),
              builder: (context, snapshot) {
                return Text(
                  _selectedMonth != null
                      ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)
                      : '-',
                );
              },
            ),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _pickMonth, child: Text('Pilih bulan')),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _fetchForReport, child: Text('Load')),
          ],
        );

      case ReportType.tahunan:
        return Row(
          children: [
            Text(_selectedYear?.toString() ?? '-'),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _pickYear, child: Text('Pilih tahun')),
            SizedBox(width: 8),
            ElevatedButton(onPressed: _fetchForReport, child: Text('Load')),
          ],
        );

      case ReportType.pembeli:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Pembeli:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                ),
                value: _selectedPembeliId,
                hint: Text('Pilih Pembeli'),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('Semua Pembeli'),
                  ),
                  ..._daftarPembeli.map<DropdownMenuItem<String>>((pembeli) {
                    final idStr = pembeli['id']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: idStr,
                      child: Text(pembeli['nama']?.toString() ?? 'Unknown'),
                    );
                  }).toList(),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedPembeliId = value;
                    if (value != null) {
                      final selected = _daftarPembeli.firstWhere(
                        (p) => p['id']?.toString() == value,
                        orElse: () => <String, dynamic>{},
                      );
                      _selectedPembeliNama = selected['nama']?.toString();
                    } else {
                      _selectedPembeliNama = null;
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 8),
            if (_selectedPembeliNama != null)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembeli: $_selectedPembeliNama',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _fetchForReport,
                  child: Text('Load Laporan'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPembeliId = null;
                      _selectedPembeliNama = null;
                      _data = [];
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text('Reset'),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (_daftarPembeli.isNotEmpty)
              Text(
                '${_daftarPembeli.length} pembeli tersedia',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            if (_data.isNotEmpty)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_data.length} transaksi ditemukan untuk pembeli ini',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
          ],
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _data.clear();
                _singleTransaksi = null;
                _selectedFaktur = null;
                _selectedPembeliId = null;
                _selected = ReportType.transaksi;
              });
              _fetchForReport();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                    label: Text('Transaksi'),
                    selected: _selected == ReportType.transaksi,
                    onSelected: (_) =>
                        setState(() => _selected = ReportType.transaksi),
                  ),
                  ChoiceChip(
                    label: Text('Harian'),
                    selected: _selected == ReportType.harian,
                    onSelected: (_) =>
                        setState(() => _selected = ReportType.harian),
                  ),
                  ChoiceChip(
                    label: Text('Bulanan'),
                    selected: _selected == ReportType.bulanan,
                    onSelected: (_) =>
                        setState(() => _selected = ReportType.bulanan),
                  ),
                  ChoiceChip(
                    label: Text('Tahunan'),
                    selected: _selected == ReportType.tahunan,
                    onSelected: (_) =>
                        setState(() => _selected = ReportType.tahunan),
                  ),
                  ChoiceChip(
                    label: Text('Pembeli'),
                    selected: _selected == ReportType.pembeli,
                    onSelected: (_) =>
                        setState(() => _selected = ReportType.pembeli),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildFilterControls(),
              SizedBox(height: 12),
              if (_loading)
                Center(child: CircularProgressIndicator())
              else if (_data.isEmpty)
                Center(child: Text('Tidak ada data'))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _data.length,
                  itemBuilder: (ctx, i) {
                    final tx = _data[i];
                    return Card(
                      child: ListTile(
                        title: Text(tx['faktur_penj'] ?? '-'),
                        subtitle: Text(
                          '${tx['nama_pembeli'] ?? '-'} - ${tx['created_at'] ?? '-'}',
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.picture_as_pdf),
                          onPressed: () async {
                            if (_selected == ReportType.transaksi) {
                              _selectedFaktur = tx['faktur_penj'];
                              await _fetchForReport();
                              final f = await _createPdfReport();
                              await Share.shareXFiles(
                                [XFile(f.path)],
                                text: 'Laporan Transaksi ${tx['faktur_penj']}',
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _data.isEmpty ? null : _exportAndShare,
                  icon: Icon(Icons.share),
                  label: Text('Share PDF & Excel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
