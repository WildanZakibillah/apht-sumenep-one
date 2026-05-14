import 'package:flutter/material.dart';
import '../core/theme.dart';

class CukaiFormScreen extends StatelessWidget {
  const CukaiFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      appBar: _buildAppBar(context, bg, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(isDark),
            const SizedBox(height: 24),
            _buildFormCard(isDark),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color bg, bool isDark) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
      ),
      title: Text(
        'Catat Pemakaian',
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
          'Pencatatan Pemakaian',
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
          'Lengkapi data penggunaan pita cukai',
          style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark) {
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
              Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Form Pemakaian',
                style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Tanggal Pencatatan', initialValue: '12 Okt 2023', suffixIcon: Icons.calendar_month_outlined),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Pemakaian Hari ini (-)', initialValue: '0', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Pita Tambahan (+) Opsional', initialValue: '0', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTextAreaField(isDark: isDark, label: 'Keterangan/Catatan', hintText: 'Tuliskan alasan pemakaian pita...'),
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
            const SnackBar(content: Text('Data berhasil disimpan')),
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
        child: const Text('Simpan Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInputField({
    required bool isDark,
    required String label,
    String? hintText,
    String? initialValue,
    IconData? suffixIcon,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: isDark ? Colors.white38 : AppTheme.outline, size: 18) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({required bool isDark, required String label, required String hintText}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}