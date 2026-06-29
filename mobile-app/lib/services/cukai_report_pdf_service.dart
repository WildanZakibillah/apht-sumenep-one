import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class CukaiReportPdfService {
  CukaiReportPdfService._();

  static Future<Uint8List> generate({
    required List<Map<String, dynamic>> allocations,
    required List<Map<String, dynamic>> usages,
    required List<Map<String, dynamic>> requests,
    required String factoryName,
    required String factoryAddress,
    required String nppbkc,
    required String ownerName,
    required DateTime period,
  }) async {
    final pdf = pw.Document();
    final dateFormatDisplay = DateFormat('dd MMM yyyy');
    final monthYear = DateFormat('MMMM yyyy').format(period);

    // 1. First Page: Cover & Summary table
    final summaryRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('Kategori Cukai', bold: true, alignRight: false),
          _cell('Alokasi Bulanan', bold: true),
          _cell('Sisa Bulan Lalu', bold: true),
          _cell('Tambahan Pengajuan', bold: true),
          _cell('Total Tersedia', bold: true),
          _cell('Terpakai', bold: true),
          _cell('Rusak', bold: true),
          _cell('Sisa Akhir', bold: true),
        ],
      )
    ];

    for (final a in allocations) {
      final cat = a['cukai_categories'] as Map<String, dynamic>?;
      final catName = cat != null ? cat['name'] ?? '-' : '-';
      final monthlyQuota = (a['monthly_quota'] as num?)?.toInt() ?? 0;
      final carryOver = (a['carry_over'] as num?)?.toInt() ?? 0;
      final additions = (a['additions'] as num?)?.toInt() ?? 0;
      final quota = (a['quota'] as num?)?.toInt() ?? 0;
      final used = (a['used'] as num?)?.toInt() ?? 0;
      final damaged = (a['damaged'] as num?)?.toInt() ?? 0;
      final remaining = (a['current_stock'] as num?)?.toInt() ?? 0;

      summaryRows.add(pw.TableRow(
        children: [
          _cell(catName, alignRight: false),
          _cell(NumberFormat('#,###').format(monthlyQuota)),
          _cell(NumberFormat('#,###').format(carryOver)),
          _cell(NumberFormat('#,###').format(additions)),
          _cell(NumberFormat('#,###').format(quota)),
          _cell(NumberFormat('#,###').format(used)),
          _cell(NumberFormat('#,###').format(damaged)),
          _cell(NumberFormat('#,###').format(remaining), bold: true),
        ],
      ));
    }

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
                pw.Text('LAPORAN PERSEDIAAN PITA CUKAI', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
        pw.Text('1. Ringkasan Stok & Quota Cukai', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: summaryRows,
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

    // 2. Second Page: Usage Logs
    final usageRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('No', bold: true, alignRight: false),
          _cell('Tanggal', bold: true, alignRight: false),
          _cell('Nama Merek / Produk', bold: true, alignRight: false),
          _cell('Excise Category', bold: true, alignRight: false),
          _cell('Dipakai (lbr)', bold: true),
          _cell('Rusak (lbr)', bold: true),
          _cell('Catatan', bold: true, alignRight: false),
        ],
      )
    ];

    int idx = 1;
    for (final u in usages) {
      final date = u['usage_date'] != null ? dateFormatDisplay.format(DateTime.parse(u['usage_date'].toString())) : '-';
      final cig = u['cigarettes'] as Map<String, dynamic>?;
      final cigName = cig != null ? cig['product_name'] ?? '-' : '-';
      final cat = aGetCategoryName(cig);
      final used = (u['used_amount'] as num?)?.toInt() ?? 0;
      final damaged = (u['damaged_amount'] as num?)?.toInt() ?? 0;
      final notes = u['notes'] ?? '-';

      usageRows.add(pw.TableRow(
        children: [
          _cell(idx.toString(), alignRight: false),
          _cell(date, alignRight: false),
          _cell(cigName, alignRight: false),
          _cell(cat, alignRight: false),
          _cell(NumberFormat('#,###').format(used)),
          _cell(NumberFormat('#,###').format(damaged)),
          _cell(notes, alignRight: false),
        ],
      ));
      idx++;
    }

    if (usages.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(children: [
          pw.Text('2. Rincian Pemakaian & Kerusakan Pita Cukai', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
        ]),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Halaman ${context.pageNumber}', style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: usageRows,
          ),
        ],
      ));
    }

    // 3. Third Page: Approved Cukai Requests
    final requestRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('No', bold: true, alignRight: false),
          _cell('Tgl Pengajuan', bold: true, alignRight: false),
          _cell('Nomor Dokumen', bold: true, alignRight: false),
          _cell('Kategori Cukai', bold: true, alignRight: false),
          _cell('Jenis Pengajuan', bold: true, alignRight: false),
          _cell('Jumlah (lbr)', bold: true),
        ],
      )
    ];

    idx = 1;
    for (final r in requests) {
      final date = r['request_date'] != null ? dateFormatDisplay.format(DateTime.parse(r['request_date'].toString())) : '-';
      final docNum = r['doc_number'] ?? '-';
      final cat = r['cukai_categories'] as Map<String, dynamic>?;
      final catName = cat != null ? cat['name'] ?? '-' : '-';
      final type = r['jenis_pengajuan'] ?? '-';
      final qty = (r['jumlah_lembar'] as num?)?.toInt() ?? 0;

      requestRows.add(pw.TableRow(
        children: [
          _cell(idx.toString(), alignRight: false),
          _cell(date, alignRight: false),
          _cell(docNum, alignRight: false),
          _cell(catName, alignRight: false),
          _cell(type, alignRight: false),
          _cell(NumberFormat('#,###').format(qty)),
        ],
      ));
      idx++;
    }

    if (requests.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(children: [
          pw.Text('3. Daftar Pengajuan Cukai yang Disetujui', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
        ]),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Halaman ${context.pageNumber}', style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (context) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: requestRows,
          ),
        ],
      ));
    }

    return pdf.save();
  }

  static String aGetCategoryName(Map<String, dynamic>? cig) {
    if (cig == null) return '-';
    final type = cig['cigarette_type'] ?? '';
    final sticks = cig['sticks_per_pack'] ?? '';
    if (type.isNotEmpty && sticks != '') {
      return '$type $sticks btg';
    }
    return '-';
  }

  static pw.Widget _cell(String text, {bool bold = false, double fontSize = 8, bool alignRight = true}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<String> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String fileName, {String? text}) async {
    final path = await savePdfToFile(pdfBytes, fileName);
    await Share.shareXFiles(
      [XFile(path)],
      text: text ?? 'Laporan Cukai - $fileName',
    );
  }
}
