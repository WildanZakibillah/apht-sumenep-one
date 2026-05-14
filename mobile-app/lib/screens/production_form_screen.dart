import 'package:flutter/material.dart';
import '../core/theme.dart';

class ProductionFormScreen extends StatefulWidget {
  const ProductionFormScreen({super.key});

  @override
  State<ProductionFormScreen> createState() => _ProductionFormScreenState();
}

class _ProductionFormScreenState extends State<ProductionFormScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(context, bg, isDark),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeader(isDark),
                  const SizedBox(height: 24),
                  _buildFormCard(isDark),
                  const SizedBox(height: 20),
                  _buildAddButton(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomAction(context, isDark),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color bg, bool isDark) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
      ),
      centerTitle: true,
      title: Text(
        'Form Produksi',
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Produksi Massal',
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
          'Isi data produksi untuk dicatat ke dalam sistem',
          style: TextStyle(
            color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
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
            const SnackBar(content: Text('Data produksi berhasil disimpan')),
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
        child: const Text(
          'Simpan Data Produksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            offset: const Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Produksi',
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Entri #1',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : AppTheme.outline,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),

          // Form Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInputField(isDark: isDark, label: 'No. Dokumen', hintText: '0001/GPM/IV/2026')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputField(isDark: isDark, label: 'Tanggal Dokumen', hintText: 'yyyy-mm-dd', suffixIcon: Icons.calendar_today_outlined)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Identitas Produk'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDropdownField(isDark: isDark, label: 'Jenis', value: 'SKT', items: ['SKT', 'SKM', 'SPM'])),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildInputField(isDark: isDark, label: 'Merek', initialValue: 'DEN HAAG')),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInputField(isDark: isDark, label: 'HJE (Rp)', initialValue: '10.325', keyboardType: TextInputType.number, prefixText: 'Rp '),
                const SizedBox(height: 16),
                _buildSectionLabel('Detail Kemasan'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildInputField(isDark: isDark, label: 'Bahan Kemasan', initialValue: 'Kertas dan Sejenisnya')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInputField(isDark: isDark, label: 'Isi', initialValue: '12', keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildInputField(isDark: isDark, label: 'Satuan', initialValue: 'btg')),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildInputField(isDark: isDark, label: 'Jumlah Kemasan', initialValue: '3.278', keyboardType: TextInputType.number)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1, color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                _buildComputedField(
                  isDark: isDark,
                  label: 'Jumlah Isi (Isi × Jml Kemasan)',
                  value: '39.336',
                  backgroundColor: AppTheme.primaryFixed.withValues(alpha: 0.35),
                  textColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required bool isDark,
    required String label,
    String? hintText,
    String? initialValue,
    String? prefixText,
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
            prefixText: prefixText,
            prefixStyle: TextStyle(color: isDark ? Colors.white54 : AppTheme.outline, fontSize: 14, fontWeight: FontWeight.w500),
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

  Widget _buildDropdownField({
    required bool isDark,
    required String label,
    required String value,
    required List<String> items,
  }) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: (String? newValue) {},
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white38 : AppTheme.outline),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildComputedField({
    required bool isDark,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color textColor,
    required Color labelColor,
    bool isPrimary = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 13, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? Border.all(color: textColor.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              Text('btg', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_circle_outline, size: 22),
      label: const Text('Tambah Baris Data Baru'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: AppTheme.surfaceContainerLowest,
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ).copyWith(
        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return BorderSide(color: AppTheme.primary, width: 2);
          }
          return BorderSide(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5);
        }),
      ),
    );
  }
}