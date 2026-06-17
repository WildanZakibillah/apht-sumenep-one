import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/production_service.dart';
import '../utils/wib_helper.dart';

class _ProductionEntry {
  String? productId;
  String jenis = '';
  String merek = '';
  String hje = '';
  String bahanKemasan = '';
  String isi = '';
  String satuan = 'btg';
  String productName = '';
  String productCode = '';
  String variant = '';
  String exciseRate = '';
  String stock = '';
  late final TextEditingController jumlahKemasanController;

  _ProductionEntry({VoidCallback? onChanged}) {
    jumlahKemasanController = TextEditingController();
    if (onChanged != null) {
      jumlahKemasanController.addListener(onChanged);
    }
  }

  String get jumlahKemasan => jumlahKemasanController.text;

  int get jumlahIsi {
    final isiVal = int.tryParse(isi) ?? 0;
    final kemasanVal = int.tryParse(jumlahKemasan) ?? 0;
    return isiVal * kemasanVal;
  }

  void dispose() {
    jumlahKemasanController.dispose();
  }
}

class ProductionFormScreen extends StatefulWidget {
  const ProductionFormScreen({super.key});

  @override
  State<ProductionFormScreen> createState() => _ProductionFormScreenState();
}

class _ProductionFormScreenState extends State<ProductionFormScreen> {
  bool _isLoading = false;
  DateTime _docDate = WIB.now();
  late String _docNumber;
  late final List<_ProductionEntry> _entries;

  // Product data from DB
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _docNumber = _generateDocNumber();
    _entries = [
      _ProductionEntry(onChanged: () {
        if (mounted) setState(() {});
      })
    ];
    _loadProducts();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  String _generateDocNumber() {
    final now = WIB.now();
    final month = _romanMonth(now.month);
    return '${now.millisecondsSinceEpoch % 10000}/GPM/$month/${now.year}';
  }

  String _romanMonth(int month) {
    const months = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
    return months[month - 1];
  }

  Future<void> _loadProducts() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return;

    try {
      final res = await Supabase.instance.client
          .from(AppConstants.tableProducts)
          .select('id, hje, sticks_per_pack, product_name, product_code, variant, satuan, bahan_kemasan, excise_rate, stock, brands(name, status), product_types(category)')
          .eq('factory_id', factoryId);

      if (mounted) {
        setState(() {
          final allProducts = List<Map<String, dynamic>>.from(res);
          // Filter to only display active brands
          _products = allProducts.where((p) {
            final brand = p['brands'] as Map<String, dynamic>?;
            return brand != null && brand['status'] == 'active';
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _docDate,
      firstDate: DateTime(2020),
      lastDate: WIB.now(),
    );
    if (picked != null) {
      setState(() => _docDate = picked);
    }
  }

  void _addEntry() {
    setState(() {
      _entries.add(_ProductionEntry(onChanged: () {
        if (mounted) setState(() {});
      }));
    });
  }

  void _removeEntry(int index) {
    if (_entries.length <= 1) return;
    final entry = _entries.removeAt(index);
    entry.dispose();
    setState(() {});
  }

  Future<void> _submitData() async {
    // Validate
    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.productId == null || e.jumlahKemasan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lengkapi data pada baris ${i + 1}'), backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || auth.profile?.factoryId == null) {
        throw Exception("Sesi pengguna tidak valid atau tidak terkait pabrik");
      }

      final factoryId = auth.profile!.factoryId!;
      final userId = auth.profile!.id;

      final productionService = ProductionService();
      for (final entry in _entries) {
        await productionService.insert({
          'doc_number': _docNumber,
          'doc_date': WIB.toDateString(_docDate),
          'product_id': entry.productId,
          'factory_id': factoryId,
          'jenis': entry.jenis,
          'merek': entry.merek,
          'hje': double.tryParse(entry.hje.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
          'bahan_kemasan': entry.bahanKemasan.isEmpty ? null : entry.bahanKemasan,
          'isi': int.tryParse(entry.isi) ?? 0,
          'satuan': entry.satuan,
          'jumlah_kemasan': int.tryParse(entry.jumlahKemasan) ?? 0,
          'jumlah_isi': entry.jumlahIsi,
          'created_by': userId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data produksi berhasil disimpan')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(context, bg, isDark),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 10, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeader(isDark),
                  const SizedBox(height: 16),
                  _buildDocInfoCard(isDark),
                  const SizedBox(height: 16),
                  ..._entries.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFormCard(isDark, e.key, e.value),
                  )),
                  _buildAddButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
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
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
      ),
      centerTitle: true,
      title: Text('Form Produksi', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPageHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Input Produksi Massal', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
        const SizedBox(height: 6),
        Text('Isi data produksi untuk dicatat ke dalam sistem', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14)),
      ],
    );
  }

  Widget _buildDocInfoCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No. Dokumen', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_docNumber, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal Dokumen', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(_docDate), style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onProductChanged(_ProductionEntry entry, String? productId) {
    if (productId == null) {
      setState(() {
        entry.productId = null;
        entry.jenis = '';
        entry.merek = '';
        entry.hje = '';
        entry.bahanKemasan = '';
        entry.isi = '';
        entry.satuan = 'btg';
        entry.productName = '';
        entry.productCode = '';
        entry.variant = '';
        entry.exciseRate = '';
        entry.stock = '';
      });
      return;
    }

    final p = _products.firstWhere((prod) => prod['id'] == productId);
    setState(() {
      entry.productId = productId;
      entry.merek = p['brands']?['name'] ?? '';
      entry.jenis = p['product_types']?['category'] ?? '';
      
      final rawHje = p['hje'] ?? 0;
      entry.hje = NumberFormat('#,###').format(rawHje);
      
      entry.bahanKemasan = p['bahan_kemasan'] ?? '';
      entry.isi = (p['sticks_per_pack'] ?? 12).toString();
      entry.satuan = p['satuan'] ?? 'btg';

      entry.productName = p['product_name'] ?? '';
      entry.productCode = p['product_code'] ?? '';
      entry.variant = p['variant'] ?? '';

      final rawExcise = p['excise_rate'] ?? 0;
      entry.exciseRate = NumberFormat('#,###').format(rawExcise);

      final rawStock = p['stock'] ?? 0;
      entry.stock = NumberFormat('#,###').format(rawStock);
    });
  }

  Widget _buildFormCard(bool isDark, int index, _ProductionEntry entry) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), offset: const Offset(0, 6), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Data Produksi', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Entri #${index + 1}', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 12)),
                  ]),
                ]),
                if (_entries.length > 1)
                  TextButton.icon(
                    onPressed: () => _removeEntry(index),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.error, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.4)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductSkuDropdown(isDark: isDark, entry: entry),
                const SizedBox(height: 16),
                if (entry.productId != null) ...[
                  _buildProductDetailsGrid(isDark: isDark, entry: entry),
                  const SizedBox(height: 16),
                  _buildEditableQuantityField(isDark: isDark, entry: entry),
                  const SizedBox(height: 16),
                  _buildComputedField(isDark: isDark, label: 'Jumlah Isi (Isi × Jml Kemasan)', value: NumberFormat('#,###').format(entry.jumlahIsi)),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : AppTheme.surfaceContainerLow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: isDark ? Colors.white30 : AppTheme.outline, size: 32),
                        const SizedBox(height: 8),
                        Text('Silakan pilih produk terlebih dahulu', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSkuDropdown({required bool isDark, required _ProductionEntry entry}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Produk (SKU)', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: entry.productId,
          hint: Text('Pilih Produk', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline)),
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: _products.map((p) {
            final brandName = p['brands']?['name'] ?? 'Produk';
            final productName = p['product_name'] ?? '';
            return DropdownMenuItem(
              value: p['id'] as String,
              child: Text('$productName ($brandName)'),
            );
          }).toList(),
          onChanged: (v) => _onProductChanged(entry, v),
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : AppTheme.outline),
          decoration: InputDecoration(
            filled: true, fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetailsGrid({required bool isDark, required _ProductionEntry entry}) {
    final detailBg = isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : AppTheme.surfaceContainerLow.withValues(alpha: 0.4);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: detailBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Nama Produk', value: entry.productName.isEmpty ? '-' : entry.productName)),
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Kode Produk', value: entry.productCode.isEmpty ? '-' : entry.productCode)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Merek', value: entry.merek)),
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Varian', value: entry.variant.isEmpty ? '-' : entry.variant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Jenis', value: entry.jenis)),
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Isi / Kemasan', value: '${entry.isi} ${entry.satuan}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'HJE', value: 'Rp ${entry.hje}')),
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Tarif Cukai / btg', value: 'Rp ${entry.exciseRate}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Stok Tersedia', value: '${entry.stock} pak')),
              Expanded(child: _buildDetailItem(isDark: isDark, label: 'Bahan Kemasan', value: entry.bahanKemasan.isEmpty ? '-' : entry.bahanKemasan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required bool isDark, required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEditableQuantityField({required bool isDark, required _ProductionEntry entry}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jml Kemasan', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: entry.jumlahKemasanController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Masukkan jml kemasan',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
            filled: true, fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildComputedField({required bool isDark, required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryFixed.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: TextStyle(color: AppTheme.primary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              Text('btg', style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return OutlinedButton.icon(
      onPressed: _addEntry,
      icon: const Icon(Icons.add_circle_outline, size: 22),
      label: const Text('Tambah Baris Data Baru'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: AppTheme.surfaceContainerLowest,
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), offset: const Offset(0, -4), blurRadius: 16)],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Simpan Data Produksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
