import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Generates P3C (Permohonan Penyediaan Pita Cukai) PDF document.
class P3cPdfService {
  P3cPdfService._();

  /// Generate P3C PDF from cukai request data.
  static Future<Uint8List> generate({
    required String docNumber,
    required String requestDate,
    required String factoryName,
    required String factoryAddress,
    required String nppbkc,
    required String ownerName,
    required String period,
    required String jenisPengajuan,
    required String lokasiPenyediaan,
    required String jenisHasilTembakau,
    required String kodePersonalisasi,
    required String seri,
    required String warna,
    required double tarifCukai,
    required double hje,
    required int isiPerBks,
    required int jumlahLembar,
    String? keterangan,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final timestampStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Timestamp top-left
            pw.Text(timestampStr, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),

            // Header: Nomor & Tanggal box + P3C label
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Nomor & Tanggal box
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(children: [
                        pw.Text('Nomor', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  :  $docNumber', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.SizedBox(height: 2),
                      pw.Row(children: [
                        pw.Text('Tanggal', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('  :  $requestDate', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ]),
                    ],
                  ),
                ),
                // P3C label
                pw.Text('P3C', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),

            pw.SizedBox(height: 16),

            // Title section - centered
            pw.Center(child: pw.Text('PERMOHONAN PENYEDIAAN PITA CUKAI', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('A.N. $factoryName, PR DI $factoryAddress', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('NPPBKC = $nppbkc', style: const pw.TextStyle(fontSize: 9))),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('PERIODE PERSEDIAAN BULAN : $period', style: const pw.TextStyle(fontSize: 9))),

            pw.SizedBox(height: 20),

            // Pengajuan & Lokasi Penyediaan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // PENGAJUAN
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('PENGAJUAN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  _buildCheckboxRow('AWAL', jenisPengajuan == 'AWAL'),
                  pw.SizedBox(height: 4),
                  _buildCheckboxRow('TAMBAHAN', jenisPengajuan == 'TAMBAHAN'),
                  pw.SizedBox(height: 4),
                  _buildCheckboxRow('TAMBAHAN IJIN DIRJEN', jenisPengajuan == 'PELENGKAP'),
                ]),
                // LOKASI PENYEDIAAN
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('LOKASI PENYEDIAAN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  _buildCheckboxRow('KPPBC/KPU', lokasiPenyediaan == 'KPPBC'),
                  pw.SizedBox(height: 4),
                  _buildCheckboxRow('KP DJBC', lokasiPenyediaan == 'KANWIL' || lokasiPenyediaan == 'LAINNYA'),
                ]),
              ],
            ),

            pw.SizedBox(height: 20),

            // Table
            _buildDataTable(
              jenisHasilTembakau: jenisHasilTembakau,
              kodePersonalisasi: kodePersonalisasi,
              seri: seri,
              warna: warna,
              tarifCukai: tarifCukai,
              hje: hje,
              isiPerBks: isiPerBks,
              jumlahLembar: jumlahLembar,
              keterangan: keterangan,
            ),

            pw.SizedBox(height: 16),

            // Disclaimer text (red)
            pw.Text(
              'Atas pita cukai yang telah kami pesan tersebut, apabila tidak direalisasikan dengan CK-1 sampai dengan akhir tahun, kami bersedia dikenakan biaya pengganti penyediaan pita cukai berdasarkan ketentuan yang berlaku.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.red),
            ),

            pw.SizedBox(height: 30),

            // Footer: note box + signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Note box
                pw.Container(
                  width: 180,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Text(
                    'Formulir ini dicetak secara\notomatis oleh sistem komputer\ndan tidak memerlukan nama,\ntanda tangan pejabat, dan cap\ndinas.',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),
                // Signature
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('$factoryAddress, $requestDate', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Pengusaha', style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 40),
                  pw.Text(ownerName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ]),
              ],
            ),
          ],
        );
      },
    ));

    return pdf.save();
  }

  static pw.Widget _buildCheckboxRow(String label, bool checked) {
    return pw.Row(children: [
      pw.Container(
        width: 14, height: 14,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: checked
            ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)))
            : pw.SizedBox(),
      ),
      pw.SizedBox(width: 8),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
    ]);
  }

  static pw.Widget _buildDataTable({
    required String jenisHasilTembakau,
    required String kodePersonalisasi,
    required String seri,
    required String warna,
    required double tarifCukai,
    required double hje,
    required int isiPerBks,
    required int jumlahLembar,
    String? keterangan,
  }) {
    final headerStyle = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold);
    const cellStyle = pw.TextStyle(fontSize: 8);

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),   // No.
        1: const pw.FixedColumnWidth(90),   // Jenis Hasil Tembakau
        2: const pw.FixedColumnWidth(80),   // Kode Personalisasi
        3: const pw.FixedColumnWidth(35),   // Seri
        4: const pw.FixedColumnWidth(45),   // Warna
        5: const pw.FixedColumnWidth(60),   // Tarif Cukai
        6: const pw.FixedColumnWidth(55),   // HJE (Rp)
        7: const pw.FixedColumnWidth(55),   // Isi/Kemasan
        8: const pw.FixedColumnWidth(60),   // Peruntukan
        9: const pw.FixedColumnWidth(65),   // Jml Pesanan
        10: const pw.FixedColumnWidth(65),  // Keterangan
      },
      children: [
        // Header row 1: with "Pita Cukai" label spanning
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _headerCell('', headerStyle),  // No. (will show in row 2)
            _headerCell('', headerStyle),  // Jenis (will show in row 2)
            _headerCell('', headerStyle),  // Kode (will show in row 2)
            // Pita Cukai spanning 6 columns
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(child: pw.Text('Pita Cukai', style: headerStyle, textAlign: pw.TextAlign.center)),
            ),
            _headerCell('', headerStyle),
            _headerCell('', headerStyle),
            _headerCell('', headerStyle),
            _headerCell('', headerStyle),
            _headerCell('', headerStyle),
            _headerCell('', headerStyle),  // Jml (will show in row 2)
            _headerCell('', headerStyle),  // Ket (will show in row 2)
          ],
        ),
        // Header row 2: actual column names
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _headerCell('No.', headerStyle),
            _headerCell('Jenis Hasil\nTembakau', headerStyle),
            _headerCell('Kode\nPersonalisasi', headerStyle),
            _headerCell('Seri', headerStyle),
            _headerCell('Warna', headerStyle),
            _headerCell('Tarif Cukai', headerStyle),
            _headerCell('HJE (Rp)', headerStyle),
            _headerCell('Isi/Kemasan', headerStyle),
            _headerCell('Peruntukan', headerStyle),
            _headerCell('Jml Pesanan\n(Lembar)', headerStyle),
            _headerCell('Keterangan', headerStyle),
          ],
        ),
        // Data row
        pw.TableRow(children: [
          _dataCell('1', cellStyle),
          _dataCell(jenisHasilTembakau, cellStyle),
          _dataCell(kodePersonalisasi, cellStyle),
          _dataCell(seri, cellStyle),
          _dataCell(warna, cellStyle),
          _dataCell(NumberFormat('#,###').format(tarifCukai.toInt()), cellStyle),
          _dataCell(NumberFormat('#,###').format(hje.toInt()), cellStyle),
          _dataCell('$isiPerBks', cellStyle),
          _dataCell('-', cellStyle),
          _dataCell(NumberFormat('#,###').format(jumlahLembar), cellStyle),
          _dataCell(keterangan ?? '', cellStyle),
        ]),
      ],
    );
  }

  static pw.Widget _headerCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Center(child: pw.Text(text, style: style, textAlign: pw.TextAlign.center)),
    );
  }

  static pw.Widget _dataCell(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: pw.Center(child: pw.Text(text, style: style, textAlign: pw.TextAlign.center)),
    );
  }

  /// Share the generated P3C PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName, {String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: text);
  }
}
