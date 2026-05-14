import 'package:flutter/material.dart';
import '../core/theme.dart';

class PengajuanCukaiScreen extends StatelessWidget {
  const PengajuanCukaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      appBar: _buildAppBar(context, bg, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(isDark),
            const SizedBox(height: 24),
            _buildDocumentCard(isDark),
            const SizedBox(height: 16),
            _buildTypeCard(isDark),
            const SizedBox(height: 16),
            _buildDetailsCard(isDark),
            const SizedBox(height: 24),
            _buildWarningSection(),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color bg, bool isDark) {
    return AppBar(
      backgroundColor: bg,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
      ),
      centerTitle: true,
      title: Text(
        'Form Pengajuan',
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permohonan Pita Cukai',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.onSurface,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Lengkapi data di bawah untuk pengajuan baru',
          style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      title: 'Informasi Dokumen',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _buildInputField(isDark: isDark, label: 'Nomor Dokumen', hintText: 'Auto / Input Manual'),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Tanggal Pengajuan', initialValue: '04 May 2026', suffixIcon: Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildTypeCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      title: 'Klasifikasi',
      icon: Icons.category_outlined,
      child: Row(
        children: [
          Expanded(child: _buildDropdownField(isDark: isDark, label: 'Jenis Pengajuan', value: 'AWAL')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(isDark: isDark, label: 'Lokasi Penyediaan', value: 'KPPBC')),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark) {
    return _buildCard(
      isDark: isDark,
      title: 'Rincian Pita Cukai',
      icon: Icons.confirmation_number_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(isDark: isDark, label: 'Jenis Hasil Tembakau', value: 'SKT'),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Kode Personalisasi', initialValue: 'GUNPAYMA00'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(isDark: isDark, label: 'Seri', initialValue: 'I', textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(isDark: isDark, label: 'Warna', initialValue: 'ME', textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(isDark: isDark, label: 'Tarif Cukai', initialValue: '122', textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(flex: 2, child: _buildInputField(isDark: isDark, label: 'HJE (Rp)', initialValue: '10.325')),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(isDark: isDark, label: 'Isi/Bks', initialValue: '12', textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(isDark: isDark, label: 'Jml Lmbar', initialValue: '100', textAlign: TextAlign.center)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorContainer.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pernyataan Kesediaan', style: TextStyle(color: AppTheme.error, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Atas pita cukai yang telah dipesan, apabila tidak direalisasikan dengan CK-1 sampai akhir tahun, bersedia dikenakan biaya pengganti.',
                  style: TextStyle(color: AppTheme.onErrorContainer, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengajuan berhasil dikirim')),
          );
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required String title, required IconData icon, required Widget child}) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required bool isDark,
    required String label,
    String? hintText,
    String? initialValue,
    IconData? suffixIcon,
    TextAlign textAlign = TextAlign.start,
  }) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          textAlign: textAlign,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: isDark ? Colors.white38 : AppTheme.outline, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required bool isDark, required String label, required String value}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : AppTheme.outline, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}