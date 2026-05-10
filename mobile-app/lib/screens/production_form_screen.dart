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
    return Scaffold(
      backgroundColor: AppTheme.surface,
      // extendBodyBehindAppBar dihapus agar form tidak menabrak AppBar
      resizeToAvoidBottomInset: false, 
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // 1. Form Content (Scrollable)
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 10, // Jarak disesuaikan karena header statis dihapus
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Teks Header dipindah ke sini agar rapi dan ikut ter-scroll
                  _buildPageHeader(), 
                  const SizedBox(height: 24),
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildAddButton(),
                ],
              ),
            ),
          ),

          // 3. Sticky Bottom Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomAction(context),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        // Warna icon diubah menjadi gelap karena background tidak lagi ungu
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.onSurface, size: 20),
      ),
      centerTitle: true,
      title: Text(
        'Form Produksi',
        style: TextStyle(
          color: AppTheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Widget baru untuk merapikan judul halaman
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input Produksi Massal',
          style: TextStyle(
            color: AppTheme.onSurface,
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
            color: AppTheme.onSurfaceVariant, // Menggunakan warna teks sekunder
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Simpan Data Produksi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 6),
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
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Produksi',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Entri #1',
                          style: TextStyle(
                            color: AppTheme.outline,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.outlineVariant.withValues(alpha: 0.4)),

          // Form Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1 — Dokumen & Tanggal
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'No. Dokumen',
                        hintText: '0001/GPM/IV/2026',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: 'Tanggal Dokumen',
                        hintText: 'yyyy-mm-dd',
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Section label
                _buildSectionLabel('Identitas Produk'),
                const SizedBox(height: 12),

                // Row 2a — Jenis & Merek (2 cols)
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Jenis',
                        value: 'SKT',
                        items: ['SKT', 'SKM', 'SPM'],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        label: 'Merek',
                        initialValue: 'DEN HAAG',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 2b — HJE (full width to avoid overflow)
                _buildInputField(
                  label: 'HJE (Rp)',
                  initialValue: '10.325',
                  keyboardType: TextInputType.number,
                  prefixText: 'Rp ',
                ),
                const SizedBox(height: 16),

                // Section label
                _buildSectionLabel('Detail Kemasan'),
                const SizedBox(height: 12),

                // Row 3a — Bahan Kemasan & Isi
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        label: 'Bahan Kemasan',
                        initialValue: 'Kertas dan Sejenisnya',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        label: 'Isi',
                        initialValue: '12',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Row 3b — Satuan & Jumlah Kemasan
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        label: 'Satuan',
                        initialValue: 'btg',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        label: 'Jumlah Kemasan',
                        initialValue: '3.278',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Divider(
                    height: 1,
                    color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),

                // Computed Result
                _buildComputedField(
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
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    String? hintText,
    String? initialValue,
    String? prefixText,
    IconData? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: AppTheme.outline,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(color: AppTheme.outline),
            filled: true,
            fillColor: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppTheme.outline, size: 18)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {},
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.outline),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.outlineVariant),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComputedField({
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
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
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
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'btg',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
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