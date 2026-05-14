import 'package:flutter/material.dart';
import '../core/theme.dart';

class KeluarFormScreen extends StatefulWidget {
  const KeluarFormScreen({super.key});

  @override
  State<KeluarFormScreen> createState() => _KeluarFormScreenState();
}

class _KeluarFormScreenState extends State<KeluarFormScreen> {
  bool _isTunai = true;

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
        'Catat Keluar',
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
          'Pencatatan Barang Keluar',
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
          'Lengkapi data distribusi barang keluar',
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
              Icon(Icons.local_shipping_outlined, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Form Barang Keluar',
                style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Tanggal Keluar', initialValue: '10/27/2023', suffixIcon: Icons.calendar_month_outlined),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Tujuan/Pelanggan', hintText: 'Nama Pelanggan atau Toko'),
          const SizedBox(height: 16),
          _buildDropdownField(isDark: isDark, label: 'Wilayah', value: 'Pilih Wilayah', items: ['Pilih Wilayah', 'Wilayah 1', 'Wilayah 2']),
          const SizedBox(height: 16),
          _buildDropdownField(isDark: isDark, label: 'Produk', value: 'Pilih Produk', items: ['Pilih Produk', 'Produk A', 'Produk B']),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Volume (Batang)', initialValue: '0', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Total Nilai (RP)', initialValue: '0', prefixText: 'Rp', keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildPaymentMethodSelector(isDark),
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
    String? prefixText,
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
            prefixIcon: prefixText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, top: 14),
                    child: Text(prefixText, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600)),
                  )
                : null,
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
          initialValue: value,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          onChanged: (String? newValue) {},
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : AppTheme.outline),
          decoration: InputDecoration(
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

  Widget _buildPaymentMethodSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metode Pembayaran', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isTunai = true),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isTunai
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF334155) : AppTheme.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isTunai ? AppTheme.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tunai',
                    style: TextStyle(
                      color: _isTunai ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isTunai = false),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !_isTunai
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF334155) : AppTheme.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_isTunai ? AppTheme.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Kredit',
                    style: TextStyle(
                      color: !_isTunai ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}