import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/outgoing_service.dart';
import '../utils/wib_helper.dart';

class KeluarFormScreen extends StatefulWidget {
  const KeluarFormScreen({super.key});

  @override
  State<KeluarFormScreen> createState() => _KeluarFormScreenState();
}

class _KeluarFormScreenState extends State<KeluarFormScreen> {
  bool _isLoading = false;
  bool _isTunai = true;
  DateTime _transactionDate = WIB.now();

  final _customerController = TextEditingController();
  final _volumeController = TextEditingController();
  final _totalValueController = TextEditingController();

  String? _selectedRegionId;
  String? _selectedProductId;
  String? _stockWarning;
  String? _packagingBreakdown;

  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _volumeController.addListener(_calculateTotalValue);
    _loadData();
  }

  @override
  void dispose() {
    _volumeController.removeListener(_calculateTotalValue);
    _customerController.dispose();
    _volumeController.dispose();
    _totalValueController.dispose();
    super.dispose();
  }

  void _calculateTotalValue() {
    if (_selectedProductId == null) return;
    try {
      final product = _products.firstWhere((p) => p['id'] == _selectedProductId);
      final hje = (product['hje'] as num?)?.toDouble() ?? 0.0;
      final volume = double.tryParse(_volumeController.text) ?? 0.0;
      final total = volume * hje;
      
      final formatter = NumberFormat('#,###');
      _totalValueController.text = formatter.format(total.toInt());

      // Stock warning logic
      final stockPacks = (product['stock'] as num?)?.toInt() ?? 0;
      final sticksPerPack = (product['sticks_per_pack'] as num?)?.toInt() ?? 12;
      final stockSticks = stockPacks * sticksPerPack;
      if (volume > stockSticks) {
        setState(() {
          _stockWarning = 'Peringatan: Volume (${volume.toInt()} btg) melebihi stok yang tersedia ($stockSticks btg / $stockPacks pak)!';
        });
      } else {
        setState(() {
          _stockWarning = null;
        });
      }

      // Packaging breakdown logic
      final volumeInt = volume.toInt();
      if (volumeInt > 0) {
        final packsPerSlop = (product['packs_per_slop'] as num?)?.toInt() ?? 10;
        final slopsPerCarton = (product['slops_per_carton'] as num?)?.toInt() ?? 20;

        final sticksPerSlop = sticksPerPack * packsPerSlop;
        final sticksPerCarton = sticksPerSlop * slopsPerCarton;

        int remainingSticks = volumeInt;

        final cartons = remainingSticks ~/ sticksPerCarton;
        remainingSticks %= sticksPerCarton;

        final slops = remainingSticks ~/ sticksPerSlop;
        remainingSticks %= sticksPerSlop;

        final packs = remainingSticks ~/ sticksPerPack;
        remainingSticks %= sticksPerPack;

        final parts = <String>[];
        if (cartons > 0) parts.add('$cartons Karton');
        if (slops > 0) parts.add('$slops Slop');
        if (packs > 0) parts.add('$packs Pak');
        if (remainingSticks > 0) parts.add('$remainingSticks Batang');

        setState(() {
          _packagingBreakdown = 'Setara dengan: ${parts.join(", ")}';
        });
      } else {
        setState(() {
          _packagingBreakdown = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;

    try {
      final regionsRes = await Supabase.instance.client.from('regions').select('id, name');
      
      List<dynamic> productsRes = [];
      if (factoryId != null) {
        productsRes = await Supabase.instance.client
            .from(AppConstants.tableProducts)
            .select('id, hje, sticks_per_pack, packs_per_slop, slops_per_carton, product_name, product_code, variant, satuan, stock, excise_rate, brands(name, status), product_types(category)')
            .eq('factory_id', factoryId);
      }

      if (mounted) {
        setState(() {
          _regions = List<Map<String, dynamic>>.from(regionsRes);
          
          final allProducts = List<Map<String, dynamic>>.from(productsRes);
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
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: WIB.now(),
    );
    if (picked != null) setState(() => _transactionDate = picked);
  }

  Future<void> _submitData() async {
    if (_customerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Isi nama pelanggan/tujuan'), backgroundColor: AppTheme.error));
      return;
    }
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Pilih produk'), backgroundColor: AppTheme.error));
      return;
    }
    final volume = int.tryParse(_volumeController.text) ?? 0;
    final totalValue = double.tryParse(_totalValueController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    if (volume <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Volume harus lebih dari 0'), backgroundColor: AppTheme.error));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || auth.profile?.factoryId == null) {
        throw Exception("Sesi pengguna tidak valid atau tidak terkait pabrik");
      }

      final factoryId = auth.profile!.factoryId!;
      final userId = auth.profile!.id;

      final service = OutgoingService();
      await service.insert({
        'transaction_date': WIB.toDateString(_transactionDate),
        'customer_name': _customerController.text,
        'region_id': _selectedRegionId,
        'product_id': _selectedProductId,
        'factory_id': factoryId,
        'volume': volume,
        'total_value': totalValue,
        'payment_method': _isTunai ? 'tunai' : 'kredit',
        'created_by': userId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data barang keluar berhasil disimpan')),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        title: Text('Catat Keluar', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pencatatan Barang Keluar', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
            const SizedBox(height: 6),
            Text('Lengkapi data distribusi barang keluar', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 24),
            _buildFormCard(isDark),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, isDark),
    );
  }

  Widget _buildFormCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.local_shipping_outlined, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Form Barang Keluar', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          _buildDateField(isDark),
          const SizedBox(height: 16),
          _buildInput(isDark: isDark, label: 'Tujuan/Pelanggan', hintText: 'Nama Pelanggan atau Toko', controller: _customerController),
          const SizedBox(height: 16),
          _buildRegionDropdown(isDark),
          const SizedBox(height: 16),
          _buildProductDropdown(isDark),
          const SizedBox(height: 16),
          _buildInput(isDark: isDark, label: 'Volume (Batang)', hintText: '0', controller: _volumeController, keyboardType: TextInputType.number),
          if (_packagingBreakdown != null) ...[
            const SizedBox(height: 6),
            Text(
              _packagingBreakdown!,
              style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
          if (_stockWarning != null) ...[
            const SizedBox(height: 6),
            Text(
              _stockWarning!,
              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          _buildInput(isDark: isDark, label: 'Total Nilai (Rp)', hintText: '0', controller: _totalValueController, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          _buildPaymentMethodSelector(isDark),
        ],
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tanggal Keluar', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      InkWell(
        onTap: _pickDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('dd MMM yyyy').format(_transactionDate), style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
            Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white38 : AppTheme.outline, size: 18),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildInput({required bool isDark, required String label, String? hintText, required TextEditingController controller, TextInputType? keyboardType}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hintText, hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
          filled: true, fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        ),
      ),
    ]);
  }

  Widget _buildRegionDropdown(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Wilayah', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: _selectedRegionId,
        hint: Text('Pilih Wilayah', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline)),
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: _regions.map((r) => DropdownMenuItem(value: r['id'] as String, child: Text(r['name'] as String))).toList(),
        onChanged: (v) => setState(() => _selectedRegionId = v),
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
    ]);
  }

  Widget _buildProductDropdown(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    Map<String, dynamic>? selectedProduct;
    if (_selectedProductId != null) {
      try {
        selectedProduct = _products.firstWhere((p) => p['id'] == _selectedProductId);
      } catch (_) {}
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Produk', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: _selectedProductId,
        hint: Text('Pilih Produk', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline)),
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: _products.map((p) {
          final brandName = p['brands']?['name'] ?? 'Produk';
          final productName = p['product_name'] ?? '';
          final stock = p['stock'] ?? 0;
          return DropdownMenuItem(
            value: p['id'] as String,
            child: Text('$productName ($brandName) — Stok: $stock pak'),
          );
        }).toList(),
        onChanged: (v) {
          setState(() {
            _selectedProductId = v;
            _calculateTotalValue();
          });
        },
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
      if (selectedProduct != null) ...[
        const SizedBox(height: 6),
        Text(
          'Stok Tersedia: ${(selectedProduct['stock'] ?? 0)} pak (${((selectedProduct['stock'] ?? 0) * (selectedProduct['sticks_per_pack'] ?? 12))} btg) | Cukai: Rp ${NumberFormat('#,###').format(selectedProduct['excise_rate'] ?? 0)}/btg',
          style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ]
    ]);
  }

  Widget _buildPaymentMethodSelector(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Metode Pembayaran', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: InkWell(
          onTap: () => setState(() => _isTunai = true),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isTunai ? AppTheme.primary.withValues(alpha: 0.1) : (isDark ? const Color(0xFF334155) : AppTheme.surface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _isTunai ? AppTheme.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text('Tunai', style: TextStyle(color: _isTunai ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant), fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        )),
        const SizedBox(width: 14),
        Expanded(child: InkWell(
          onTap: () => setState(() => _isTunai = false),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: !_isTunai ? AppTheme.primary.withValues(alpha: 0.1) : (isDark ? const Color(0xFF334155) : AppTheme.surface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: !_isTunai ? AppTheme.primary : (isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text('Kredit', style: TextStyle(color: !_isTunai ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant), fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        )),
      ]),
    ]);
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
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Simpan Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
