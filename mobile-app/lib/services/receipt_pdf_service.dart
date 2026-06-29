import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  static Future<Uint8List> generate({
    required String title,
    required String transactionDate,
    required String customerName,
    required String productMerek,
    required String volume,
    required String totalValue,
    required String paymentMethod,
    required String hje,
    required String exciseRate,
    required String factoryName,
    required String status,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          180 * PdfPageFormat.mm,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          final fontNormal = pw.TextStyle(fontSize: 8, color: PdfColors.black);
          final fontBold = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
          final fontHeader = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
          final fontSubtitle = pw.TextStyle(fontSize: 7, color: PdfColors.grey700);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Center(child: pw.Text(factoryName.toUpperCase(), style: fontHeader, textAlign: pw.TextAlign.center)),
              pw.SizedBox(height: 2),
              pw.Center(child: pw.Text('APHT SUMENEP ONE — SISTEM DIGITAL', style: fontSubtitle, textAlign: pw.TextAlign.center)),
              pw.SizedBox(height: 8),

              // Dashed line
              _buildDashedLine(),
              pw.SizedBox(height: 6),

              // Title
              pw.Center(child: pw.Text('STRUK PENJUALAN / PENGELUARAN', style: fontBold)),
              pw.SizedBox(height: 6),

              // Details metadata
              _buildRow('Tanggal', transactionDate, fontNormal, fontNormal),
              _buildRow('Pelanggan', customerName, fontNormal, fontNormal),
              _buildRow('Metode', paymentMethod, fontNormal, fontNormal),
              _buildRow('Status', status, fontNormal, fontBold),
              pw.SizedBox(height: 6),

              // Dashed line
              _buildDashedLine(),
              pw.SizedBox(height: 6),

              // Item details
              pw.Text('PRODUK / MEREK:', style: fontBold),
              pw.Text(productMerek, style: fontNormal),
              pw.SizedBox(height: 4),
              _buildRow('Volume', volume, fontNormal, fontNormal),
              if (hje != '-' && hje.isNotEmpty) _buildRow('HJE Pack', hje, fontSubtitle, fontSubtitle),
              if (exciseRate != '-' && exciseRate.isNotEmpty) _buildRow('Tarif Cukai', exciseRate, fontSubtitle, fontSubtitle),
              pw.SizedBox(height: 6),

              // Dashed line
              _buildDashedLine(),
              pw.SizedBox(height: 6),

              // Total section
              _buildRow('TOTAL BELANJA', totalValue, fontBold, fontBold),
              pw.SizedBox(height: 12),

              // Dashed line
              _buildDashedLine(),
              pw.SizedBox(height: 8),

              // Footer
              pw.Center(child: pw.Text('TERIMA KASIH', style: fontBold)),
              pw.SizedBox(height: 2),
              pw.Center(child: pw.Text('APHT SUMENEP ONE', style: fontSubtitle)),
              pw.SizedBox(height: 8),

              // Barcode visual simulation
              pw.Center(
                child: pw.Container(
                  width: 50 * PdfPageFormat.mm,
                  height: 6 * PdfPageFormat.mm,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: List.generate(
                      15,
                      (index) => pw.Container(
                        width: (index % 3 == 0) ? 2 : 1,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Flexible(child: pw.Text(value, style: valueStyle, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _buildDashedLine() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: List.generate(
        35,
        (_) => pw.Container(
          width: 3,
          height: 0.5,
          color: PdfColors.grey500,
        ),
      ),
    );
  }

  /// Share the generated POS Receipt PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName, {String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
