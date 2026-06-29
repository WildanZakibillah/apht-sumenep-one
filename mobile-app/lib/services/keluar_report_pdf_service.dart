import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class KeluarReportPdfService {
  KeluarReportPdfService._();

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

  static Future<Uint8List> generate({
    required List<Map<String, dynamic>> outgoing,
    required String factoryName,
    required String factoryAddress,
    required String nppbkc,
    required String ownerName,
    required DateTime period,
  }) async {
    final pdf = pw.Document();
    final dateFormatDisplay = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final monthYear = DateFormat('MMMM yyyy').format(period);

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('No', bold: true, alignRight: false),
          _cell('Tanggal', bold: true, alignRight: false),
          _cell('Doc No', bold: true, alignRight: false),
          _cell('Merek / Produk', bold: true, alignRight: false),
          _cell('Pelanggan / Distributor', bold: true, alignRight: false),
          _cell('Volume (btg)', bold: true),
          _cell('Kuantitas (kemasan)', bold: true),
          _cell('HJE/Kemasan', bold: true),
          _cell('Total HJE (Rp)', bold: true),
          _cell('Status', bold: true, alignRight: false),
        ],
      )
    ];

    int idx = 1;
    int totalVolume = 0;
    int totalPacks = 0;
    double totalHje = 0;

    for (final o in outgoing) {
      final date = o['transaction_date'] != null ? dateFormatDisplay.format(DateTime.parse(o['transaction_date'].toString())) : '-';
      final docNum = o['doc_number'] ?? '-';
      final customer = o['customer_name'] ?? '-';
      
      final cig = o['cigarettes'] as Map<String, dynamic>?;
      final cigName = cig != null ? cig['product_name'] ?? '-' : '-';
      final brand = cig != null ? cig['brands'] as Map<String, dynamic>? : null;
      final brandName = brand != null ? brand['name'] ?? '' : '';
      
      final displayProduct = brandName.isNotEmpty ? '$cigName ($brandName)' : cigName;

      final vol = (o['volume'] as num?)?.toInt() ?? 0;
      final sticksPerPack = cig != null ? (cig['sticks_per_pack'] as num?)?.toInt() ?? 12 : 12;
      final packs = vol ~/ sticksPerPack;
      final unitHje = cig != null ? (cig['hje'] as num?)?.toDouble() ?? 0.0 : 0.0;
      final hje = (o['total_value'] as num?)?.toDouble() ?? 0.0;
      final status = o['status'] ?? '-';

      totalVolume += vol;
      totalPacks += packs;
      totalHje += hje;

      tableRows.add(pw.TableRow(
        children: [
          _cell(idx.toString(), alignRight: false),
          _cell(date, alignRight: false),
          _cell(docNum, alignRight: false),
          _cell(displayProduct, alignRight: false),
          _cell(customer, alignRight: false),
          _cell(NumberFormat('#,###').format(vol)),
          _cell(NumberFormat('#,###').format(packs)),
          _cell(currencyFormat.format(unitHje)),
          _cell(currencyFormat.format(hje)),
          _cell(status.toUpperCase(), alignRight: false, bold: true),
        ],
      ));
      idx++;
    }

    // Add totals row
    tableRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      children: [
        _cell('', alignRight: false),
        _cell('', alignRight: false),
        _cell('', alignRight: false),
        _cell('TOTAL LAPORAN', bold: true, alignRight: false),
        _cell('', alignRight: false),
        _cell(NumberFormat('#,###').format(totalVolume), bold: true),
        _cell(NumberFormat('#,###').format(totalPacks), bold: true),
        _cell('', alignRight: false),
        _cell(currencyFormat.format(totalHje), bold: true),
        _cell('', alignRight: false),
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
                pw.Text('LAPORAN PENGELUARAN / PENJUALAN BARANG', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
      text: text ?? 'Laporan Barang Keluar - $fileName',
    );
  }
}
