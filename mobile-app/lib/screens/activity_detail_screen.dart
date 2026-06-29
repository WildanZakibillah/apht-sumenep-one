import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/theme.dart';
import '../services/p3c_pdf_service.dart';
import '../services/receipt_pdf_service.dart';

class ActivityDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String date;
  final IconData icon;
  final Color color;
  final Map<String, String> details;

  const ActivityDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.date,
    required this.icon,
    required this.color,
    required this.details,
  });

  Future<Uint8List> _generateDetailPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text('BUKTI TRANSAKSI', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('APHT Sumenep One', style: const pw.TextStyle(fontSize: 10))),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Status: $status', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Tanggal: $date', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Jumlah/Nominal: $amount', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 16),
            pw.Text('RINCIAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            ...details.entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(e.value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            )),
            pw.SizedBox(height: 30),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('Dokumen ini dicetak secara otomatis oleh sistem APHT Sumenep One', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
          ],
        );
      },
    ));
    return pdf.save();
  }

  Future<void> _share(BuildContext context) async {
    // Check if this is a Pengajuan Cukai - use P3C format
    if (status.toLowerCase() == 'pengajuan') {
      await _shareP3c(context);
      return;
    }

    // Check if this is Outgoing Goods - use Receipt PDF format
    if (status.toLowerCase() == 'keluar') {
      await _shareReceipt(context);
      return;
    }

    final pdfBytes = await _generateDetailPdf();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/detail_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$title - $amount',
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final pdfBytes = await ReceiptPdfService.generate(
      title: title,
      transactionDate: details['Tanggal'] ?? date,
      customerName: details['Pelanggan'] ?? '-',
      productMerek: details['Produk / Merek'] ?? title,
      volume: details['Volume'] ?? amount,
      totalValue: details['Total Nilai'] ?? amount,
      paymentMethod: details['Pembayaran'] ?? '-',
      hje: details['HJE'] ?? '-',
      exciseRate: details['Tarif Cukai'] ?? '-',
      factoryName: details['Nama Pabrik'] ?? 'APHT Sumenep One',
      status: details['Status'] ?? 'PENDING',
    );

    await ReceiptPdfService.sharePdf(
      pdfBytes,
      'Struk_Penjualan_${details['Pelanggan']?.replaceAll(' ', '_') ?? 'transaksi'}.pdf',
      text: 'Struk Penjualan - ${details['Pelanggan'] ?? ''}',
    );
  }

  Future<void> _shareP3c(BuildContext context) async {
    // Extract data from details map for P3C PDF
    final pdfBytes = await P3cPdfService.generate(
      docNumber: details['No. Dokumen'] ?? '-',
      requestDate: details['Tanggal'] ?? date,
      factoryName: details['Nama Pabrik'] ?? '-',
      factoryAddress: details['Alamat Pabrik'] ?? '-',
      nppbkc: details['NPPBKC'] ?? '-',
      ownerName: details['Nama Pengusaha'] ?? '-',
      period: details['Tanggal'] ?? '-',
      jenisPengajuan: details['Jenis Pengajuan'] ?? 'AWAL',
      lokasiPenyediaan: details['Lokasi Penyediaan'] ?? 'KPPBC',
      jenisHasilTembakau: details['Jenis Tembakau'] ?? '-',
      kodePersonalisasi: details['Kode Personalisasi'] ?? '-',
      seri: details['Seri'] ?? '-',
      warna: details['Warna'] ?? '-',
      tarifCukai: double.tryParse((details['Tarif Cukai'] ?? '0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      hje: double.tryParse((details['HJE'] ?? '0').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      isiPerBks: int.tryParse((details['Isi/Bks'] ?? '0').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      jumlahLembar: int.tryParse((details['Jumlah Lembar'] ?? '0').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    );

    // Share directly as PDF file without preview
    await P3cPdfService.sharePdf(
      pdfBytes,
      'P3C_${details['No. Dokumen'] ?? 'pengajuan'}.pdf',
      text: 'Pengajuan Cukai - ${details['No. Dokumen'] ?? ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
        ),
        title: Text('Detail Aktivitas', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _share(context),
            icon: Icon(Icons.share_rounded, color: isDark ? Colors.white70 : AppTheme.outline, size: 22),
            tooltip: 'Bagikan',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeroSection(isDark),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: _buildDetailsCard(isDark)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.65)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Nominal / Jumlah', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    // Filter out fields that are only for PDF generation or duplicate
    final hiddenKeys = {'tanggal', 'nama pabrik', 'alamat pabrik', 'nppbkc', 'nama pengusaha'};
    final filteredDetails = Map<String, String>.from(details)
      ..removeWhere((key, _) => hiddenKeys.contains(key.toLowerCase()));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Text('Info Detail', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
        Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(children: [
            _buildDetailRow(isDark, 'Tanggal', date),
            const SizedBox(height: 14),
            ...filteredDetails.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildDetailRow(isDark, entry.key, entry.value),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 2, child: Text(label, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.outline, fontSize: 13, fontWeight: FontWeight.w500))),
      const SizedBox(width: 16),
      Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600))),
    ]);
  }
}
