import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/theme.dart';

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

  Future<void> _download(BuildContext context) async {
    final pdfBytes = await _generateDetailPdf();
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> _share(BuildContext context) async {
    final pdfBytes = await _generateDetailPdf();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/detail_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '$title - $amount',
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
            Padding(padding: const EdgeInsets.all(20), child: _buildDetailsCard(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _download(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.5))),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.8)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: Icon(icon, size: 150, color: Colors.white.withValues(alpha: 0.1))),
          Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5)),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 32),
            Text('Nominal / Jumlah', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0)),
          ]),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 12),
            Text('Rincian Transaksi', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
        Divider(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            _buildDetailRow(isDark, 'Tanggal', date),
            const SizedBox(height: 16),
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
