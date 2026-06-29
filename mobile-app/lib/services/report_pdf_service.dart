import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Generates CK-4 style PDF report for production data.
class ReportPdfService {
  ReportPdfService._();

  /// Generate CK-4 PDF from production data.
  /// [productions] is a list of maps with keys: doc_number, doc_date, jenis, merek, hje, bahan_kemasan, isi, satuan, jumlah_kemasan, jumlah_isi
  /// [factoryName], [factoryAddress], [nppbkc], [ownerName] are factory info.
  /// [periodStart], [periodEnd] define the reporting period.
  static Future<Uint8List> generateCK4({
    required List<Map<String, dynamic>> productions,
    required String factoryName,
    required String factoryAddress,
    required String nppbkc,
    required String ownerName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime reportDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MM-yyyy');
    final dateFormatDisplay = DateFormat('dd MMM yyyy');

    // Calculate totals
    int totalKemasan = 0;
    int totalIsi = 0;
    for (final p in productions) {
      totalKemasan += (p['jumlah_kemasan'] as int?) ?? 0;
      totalIsi += (p['jumlah_isi'] as int?) ?? 0;
    }

    // Page 1: Cover
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Nomor    : ${productions.isNotEmpty ? productions.first['doc_number'] ?? '-' : '-'}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Tanggal  : ${dateFormatDisplay.format(reportDate)}', style: const pw.TextStyle(fontSize: 10)),
                ]),
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('CK-4 C', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Center(child: pw.Text('PEMBERITAHUAN HASIL TEMBAKAU', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('YANG SELESAI DIBUAT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 24),
            pw.Text('Dengan ini diberitahukan bahwa mulai tanggal ${dateFormat.format(periodStart)} sampai dengan tanggal ${dateFormat.format(periodEnd)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('pabrik kami :', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            _buildInfoRow('Nama', factoryName),
            pw.SizedBox(height: 8),
            _buildInfoRow('Alamat', factoryAddress),
            pw.SizedBox(height: 8),
            _buildInfoRow('NPPBKC', nppbkc),
            pw.SizedBox(height: 20),
            pw.Text(
              'telah memproduksi hasil tembakau yang sudah dikemas untuk penjualan eceran sebanyak :',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              '${NumberFormat('#,###').format(totalKemasan)} kemasan yang keseluruhannya berjumlah ${NumberFormat('#,###').format(totalIsi)} batang dan/atau, 0 gram dan/atau, 0 Mililiter, yang perinciannya seperti tersebut di balik pemberitahuan ini.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Demikian telah diberitahukan dengan sebenarnya.', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 30),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Text('Pengusaha', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 40),
                pw.Text(ownerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ],
        );
      },
    ));

    // Page 2+: Detail table
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('No', bold: true),
          _cell('Nomor', bold: true),
          _cell('Tanggal', bold: true),
          _cell('Jenis', bold: true),
          _cell('Merek', bold: true),
          _cell('HJE (Rp)', bold: true),
          _cell('Bahan', bold: true),
          _cell('Isi', bold: true),
          _cell('Satuan', bold: true),
          _cell('Jml', bold: true),
          _cell('Jml Isi', bold: true),
        ],
      ),
    ];

    for (int i = 0; i < productions.length; i++) {
      final p = productions[i];
      tableRows.add(pw.TableRow(children: [
        _cell('${i + 1}'),
        _cell(p['doc_number'] ?? '-', fontSize: 7),
        _cell(p['doc_date'] ?? '-', fontSize: 7),
        _cell(p['jenis'] ?? '-'),
        _cell(p['merek'] ?? '-', fontSize: 7),
        _cell(NumberFormat('#,###').format(p['hje'] ?? 0), fontSize: 7),
        _cell(p['bahan_kemasan'] ?? '-', fontSize: 6),
        _cell('${p['isi'] ?? 0}'),
        _cell(p['satuan'] ?? 'btg'),
        _cell(NumberFormat('#,###').format(p['jumlah_kemasan'] ?? 0)),
        _cell(NumberFormat('#,###').format(p['jumlah_isi'] ?? 0)),
      ]));
    }

    // Total row
    tableRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      children: [
        _cell(''), _cell(''), _cell(''), _cell(''), _cell('JUMLAH', bold: true), _cell(''), _cell(''), _cell(''), _cell(''),
        _cell(NumberFormat('#,###').format(totalKemasan), bold: true),
        _cell(NumberFormat('#,###').format(totalIsi), bold: true),
      ],
    ));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      header: (context) => pw.Column(children: [
        pw.Center(child: pw.Text('RINCIAN PEMBERITAHUAN PRODUKSI', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.Center(child: pw.Text('HASIL TEMBAKAU', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 16),
      ]),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Halaman ${context.pageNumber}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: tableRows,
        ),
        pw.SizedBox(height: 30),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
            pw.Text('Sumenep, tanggal ${dateFormatDisplay.format(reportDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Pengusaha', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 40),
            pw.Text(ownerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ]),
        ),
      ],
    ));

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(children: [
      pw.SizedBox(width: 80, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
      pw.Text(':  $value', style: const pw.TextStyle(fontSize: 10)),
    ]);
  }

  static pw.Widget _cell(String text, {bool bold = false, double fontSize = 8, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Align(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
    );
  }

  /// Generate actual stock inventory PDF report.
  static Future<Uint8List> generateStockReport({
    required List<Map<String, dynamic>> cigarettes,
    required String factoryName,
    required String factoryAddress,
    required String nppbkc,
    required String ownerName,
    required DateTime period,
  }) async {
    final pdf = pw.Document();
    final dateFormatDisplay = DateFormat('dd MMM yyyy');
    final monthYear = DateFormat('MMMM yyyy').format(period);

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('No', bold: true, alignRight: false),
          _cell('Nama Merek / Produk', bold: true, alignRight: false),
          _cell('Jenis', bold: true, alignRight: false),
          _cell('Isi (btg)', bold: true, alignRight: true),
          _cell('Stok Belum Dilekati (lbr/kemasan)', bold: true, alignRight: true),
          _cell('Stok Siap Jual (kemasan)', bold: true, alignRight: true),
          _cell('Total Stok (kemasan)', bold: true, alignRight: true),
          _cell('Total Stok (batang)', bold: true, alignRight: true),
        ],
      )
    ];

    int idx = 1;
    int totalUnaffixed = 0;
    int totalReady = 0;
    int totalPacks = 0;
    int totalSticks = 0;

    for (final c in cigarettes) {
      final cigName = c['product_name'] ?? '-';
      final brand = c['brands'] as Map<String, dynamic>?;
      final brandName = brand != null ? brand['name'] ?? '' : '';
      final displayProduct = brandName.isNotEmpty ? '$cigName ($brandName)' : cigName;
      final type = c['cigarette_type'] ?? '-';
      
      final isi = (c['sticks_per_pack'] as num?)?.toInt() ?? 12;
      final unaffixed = (c['unaffixed_stock'] as num?)?.toInt() ?? 0;
      final ready = (c['stock'] as num?)?.toInt() ?? 0;
      
      final sumPacks = unaffixed + ready;
      final sumSticks = sumPacks * isi;

      totalUnaffixed += unaffixed;
      totalReady += ready;
      totalPacks += sumPacks;
      totalSticks += sumSticks;

      tableRows.add(pw.TableRow(
        children: [
          _cell(idx.toString(), alignRight: false),
          _cell(displayProduct, alignRight: false),
          _cell(type, alignRight: false),
          _cell(NumberFormat('#,###').format(isi), alignRight: true),
          _cell(NumberFormat('#,###').format(unaffixed), alignRight: true),
          _cell(NumberFormat('#,###').format(ready), alignRight: true),
          _cell(NumberFormat('#,###').format(sumPacks), alignRight: true),
          _cell(NumberFormat('#,###').format(sumSticks), alignRight: true),
        ],
      ));
      idx++;
    }

    // Add totals row
    tableRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      children: [
        _cell('', alignRight: false),
        _cell('TOTAL LAPORAN', bold: true, alignRight: false),
        _cell('', alignRight: false),
        _cell('', alignRight: true),
        _cell(NumberFormat('#,###').format(totalUnaffixed), bold: true, alignRight: true),
        _cell(NumberFormat('#,###').format(totalReady), bold: true, alignRight: true),
        _cell(NumberFormat('#,###').format(totalPacks), bold: true, alignRight: true),
        _cell(NumberFormat('#,###').format(totalSticks), bold: true, alignRight: true),
      ],
    ));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      header: (context) => pw.Column(children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN PERSEDIAAN STOK BARANG', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Pabrik: $factoryName | NPPBKC: $nppbkc', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Text('Periode: $monthYear', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 16),
      ]),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Halaman ${context.pageNumber}', style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: tableRows,
        ),
        pw.SizedBox(height: 40),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Sumenep, ${dateFormatDisplay.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Pengusaha Pabrik', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 40),
              pw.Text(ownerName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
    ));

    return pdf.save();
  }

  /// Save PDF to temp file and return the file path.
  static Future<String> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  /// Share PDF file.
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName, {String? text}) async {
    final path = await savePdfToFile(pdfBytes, fileName);
    await Share.shareXFiles(
      [XFile(path)],
      text: text ?? 'Laporan - $fileName',
    );
  }
}
