import 'package:flutter/material.dart';
import '../core/theme.dart';

class KeluarFormScreen extends StatefulWidget {
  const KeluarFormScreen({super.key});

  @override
  State<KeluarFormScreen> createState() => _KeluarFormScreenState();
}

class _KeluarFormScreenState extends State<KeluarFormScreen> {
  bool _isTunai = true;

  @override Widget build(BuildContext context) { return Scaffold( resizeToAvoidBottomInset: false, backgroundColor: AppTheme.surface, appBar: _buildAppBar(context), body: SingleChildScrollView( padding: const EdgeInsets.fromLTRB(20, 10, 20, 140), child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [ _buildHeaderInfo(), const SizedBox(height: 24), _buildFormCard(), ], ), ), bottomSheet: _buildBottomAction(context), ); }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppTheme.onSurface,
          size: 20,
        ),
      ),
      title: Text(
        'Catat Keluar',
        style: TextStyle(
          color: AppTheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pencatatan Barang Keluar',
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
          'Lengkapi data distribusi barang keluar',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Form Barang Keluar',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildInputField(
            label: 'Tanggal Keluar',
            initialValue: '10/27/2023',
            suffixIcon: Icons.calendar_month_outlined,
          ),

          const SizedBox(height: 16),

          _buildInputField(
            label: 'Tujuan/Pelanggan',
            hintText: 'Nama Pelanggan atau Toko',
          ),

          const SizedBox(height: 16),

          _buildDropdownField(
            label: 'Wilayah',
            value: 'Pilih Wilayah',
            items: ['Pilih Wilayah', 'Wilayah 1', 'Wilayah 2'],
          ),

          const SizedBox(height: 16),

          _buildDropdownField(
            label: 'Produk',
            value: 'Pilih Produk',
            items: ['Pilih Produk', 'Produk A', 'Produk B'],
          ),

          const SizedBox(height: 16),

          _buildInputField(
            label: 'Volume (Batang)',
            initialValue: '0',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          _buildInputField(
            label: 'Total Nilai (RP)',
            initialValue: '0',
            prefixText: 'Rp',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 20),

          _buildPaymentMethodSelector(),
        ],
      ),
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
            const SnackBar(content: Text('Data berhasil disimpan')),
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
          'Simpan Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? hintText,
    String? initialValue,
    IconData? suffixIcon,
    String? prefixText,
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
            hintStyle: TextStyle(color: AppTheme.outline),
            filled: true,
            fillColor:
                AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            prefixIcon: prefixText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, top: 14),
                    child: Text(
                      prefixText,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primary, width: 2),
            ),

            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    color: AppTheme.outline,
                    size: 18,
                  )
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
          initialValue: value,
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

          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.outline,
          ),

          decoration: InputDecoration(
            filled: true,
            fillColor:
                AppTheme.surfaceContainerLow.withValues(alpha: 0.5),

            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.outlineVariant),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.outlineVariant),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isTunai = true;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isTunai
                        ? AppTheme.surfaceContainerLow
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isTunai
                          ? AppTheme.primary
                          : AppTheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Tunai',
                    style: TextStyle(
                      color: _isTunai
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
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
                onTap: () {
                  setState(() {
                    _isTunai = false;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: !_isTunai
                        ? AppTheme.surfaceContainerLow
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: !_isTunai
                          ? AppTheme.primary
                          : AppTheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Kredit',
                    style: TextStyle(
                      color: !_isTunai
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
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