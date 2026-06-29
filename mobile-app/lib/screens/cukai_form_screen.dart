import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/cukai_usage_service.dart';
import '../utils/wib_helper.dart';

class CukaiFormScreen extends StatefulWidget {
  const CukaiFormScreen({super.key});

  @override
  State<CukaiFormScreen> createState() => _CukaiFormScreenState();
}

class _CukaiFormScreenState extends State<CukaiFormScreen> {
  bool _isLoading = false;
  DateTime _usageDate = WIB.now();
  List<Map<String, dynamic>> _products = [];

  // List of pemakaian cukai entries
  late final List<_CukaiEntry> _entries;

  // Allocation list
  List<Map<String, dynamic>> _allocationList = [];

  @override
  void initState() {
    super.initState();
    _entries = [
      _CukaiEntry(onChanged: () {
        if (mounted) setState(() {});
      })
    ];
    _loadInitData();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitData() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final factoryId = auth.profile?.factoryId;
      if (factoryId == null) return;

      final now = WIB.now();
      final period = 'Q${((now.month - 1) ~/ 3) + 1}-${now.year}';

      final res = await Supabase.instance.client
          .from('cukai_allocations')
          .select()
          .eq('factory_id', factoryId)
          .eq('period', period);

      final list = List<Map<String, dynamic>>.from(res);
      if (list.isEmpty) {
        final newAlloc = await Supabase.instance.client
            .from('cukai_allocations')
            .insert({
              'factory_id': factoryId,
              'quota': 50000,
              'used': 0,
              'damaged': 0,
              'period': period,
            })
            .select()
            .single();
        _allocationList = [newAlloc];
      } else {
        _allocationList = list;
      }

      final prodRes = await Supabase.instance.client
          .from('cigarettes')
          .select('*, brands(name), cukai_categories(*)')
          .eq('factory_id', factoryId);
      _products = List<Map<String, dynamic>>.from(prodRes);

      // Pre-select product for the first entry
      if (_products.isNotEmpty && _entries.isNotEmpty) {
        _onProductChanged(_entries.first, _products.first['id'] as String);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onProductChanged(_CukaiEntry entry, String? newProductId) {
    if (newProductId == null) return;
    entry.productId = newProductId;
    setState(() {});
  }

  Map<String, dynamic>? _getMatchingAllocation(String productId) {
    if (_products.isEmpty || _allocationList.isEmpty) return null;
    try {
      final selectedProduct = _products.firstWhere((p) => p['id'] == productId);
      final catId = selectedProduct['cukai_category_id'] as String?;
      
      // 1. Find matching allocation by cukai_category_id first
      if (catId != null) {
        for (final a in _allocationList) {
          if (a['cukai_category_id'] == catId) return a;
        }
      }

      // 2. Find matching allocation specifically for this product (legacy fallback)
      for (final a in _allocationList) {
        if (a['product_id'] == productId) return a;
      }
      
      // 3. Find matching allocation by specs (for legacy shared allocations)
      final selectedCategory = selectedProduct['cukai_categories']?['jenis_ht'] ?? '';
      final selectedIsi = (selectedProduct['sticks_per_pack'] as num?)?.toInt() ?? 0;
      final selectedHje = (selectedProduct['hje'] as num?)?.toDouble() ?? 0.0;
      for (final a in _allocationList) {
        if (a['product_id'] != null) {
          final aProd = _products.firstWhere((p) => p['id'] == a['product_id'], orElse: () => {});
          if (aProd.isNotEmpty) {
            final aCategory = aProd['cukai_categories']?['jenis_ht'] ?? '';
            final aIsi = (aProd['sticks_per_pack'] as num?)?.toInt() ?? 0;
            final aHje = (aProd['hje'] as num?)?.toDouble() ?? 0.0;
            if (aCategory == selectedCategory && aIsi == selectedIsi && aHje == selectedHje) {
              return a;
            }
          }
        }
      }

      // 4. Fallback to general factory allocation (product_id is null)
      for (final a in _allocationList) {
        if (a['product_id'] == null && a['cukai_category_id'] == null) return a;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  void _addEntry() {
    setState(() {
      final newEntry = _CukaiEntry(onChanged: () {
        if (mounted) setState(() {});
      });
      _entries.add(newEntry);
      if (_products.isNotEmpty) {
        _onProductChanged(newEntry, _products.first['id'] as String);
      }
    });
  }

  void _removeEntry(int index) {
    if (_entries.length > 1) {
      setState(() {
        _entries[index].dispose();
        _entries.removeAt(index);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _usageDate,
      firstDate: DateTime(2020),
      lastDate: WIB.now(),
    );
    if (picked != null) setState(() => _usageDate = picked);
  }

  Future<void> _submitData() async {
    // 1. Validation
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pilih produk rokok pada entri #${i + 1}'), backgroundColor: AppTheme.error),
        );
        return;
      }
      
      final alloc = _getMatchingAllocation(entry.productId!);
      if (alloc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stok/Alokasi pita cukai untuk spesifikasi produk pada entri #${i + 1} tidak tersedia'), backgroundColor: AppTheme.error),
        );
        return;
      }

      final used = int.tryParse(entry.usedController.text) ?? 0;
      final damaged = int.tryParse(entry.damagedController.text) ?? 0;
      final totalNeeded = used + damaged;

      if (totalNeeded <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Masukkan jumlah pita dipakai atau rusak pada entri #${i + 1}'), backgroundColor: AppTheme.error),
        );
        return;
      }

      final remainingStamps = (alloc['quota'] as num).toInt() - (alloc['used'] as num).toInt() - ((alloc['damaged'] as num?)?.toInt() ?? 0);

      if (totalNeeded > remainingStamps) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Total pengeluaran (${NumberFormat('#,###').format(totalNeeded)} lbr) pada entri #${i + 1} melebihi sisa alokasi pita cukai (${NumberFormat('#,###').format(remainingStamps)} lbr)!'), backgroundColor: AppTheme.error),
        );
        return;
      }

      final prod = _products.firstWhere((p) => p['id'] == entry.productId);
      final unaffixedStock = (prod['unaffixed_stock'] as num?)?.toInt() ?? 0;
      if (used > unaffixedStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah pita dipakai (${NumberFormat('#,###').format(used)} lbr) pada entri #${i + 1} melebihi stok rokok belum dilekati (${NumberFormat('#,###').format(unaffixedStock)} kemasan)!'), backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    // 2. Prepare confirmation message
    final buffer = StringBuffer();
    buffer.write('Apakah Anda yakin ingin mencatat pemakaian pita cukai berikut?\n\n');
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final prod = _products.firstWhere((p) => p['id'] == entry.productId);
      final used = int.tryParse(entry.usedController.text) ?? 0;
      final damaged = int.tryParse(entry.damagedController.text) ?? 0;
      buffer.write('${i + 1}. ${prod['product_name']} (${prod['brands']?['name'] ?? ''})\n');
      buffer.write('   Dipakai: ${NumberFormat('#,###').format(used)} lbr • Rusak: ${NumberFormat('#,###').format(damaged)} lbr\n\n');
    }
    buffer.write('Tindakan ini akan otomatis memotong stok pita cukai dan menambah stok rokok jadi.');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pemakaian', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(buffer.toString()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || auth.profile?.factoryId == null) {
        throw Exception("Sesi pengguna tidak valid atau tidak terkait pabrik");
      }

      final factoryId = auth.profile!.factoryId!;
      final userId = auth.profile!.id;

      final service = CukaiUsageService();
      final client = Supabase.instance.client;
      
      // Save all entries sequentially
      for (final entry in _entries) {
        final used = int.tryParse(entry.usedController.text) ?? 0;
        final damaged = int.tryParse(entry.damagedController.text) ?? 0;
        
        if (used <= 0 && damaged <= 0) continue;

        final product = _products.firstWhere((p) => p['id'] == entry.productId);
        final productName = product['product_name'] ?? 'Rokok';
        final cat = product['cukai_categories'] as Map<String, dynamic>?;
        final catId = cat != null ? cat['id'] as String? : null;
        final isShared = cat != null ? (cat['is_shared'] ?? true) : true;

        var query = client
            .from('cukai_requests')
            .select('id, quantity_remaining, doc_number')
            .eq('factory_id', factoryId)
            .eq('status', 'approved')
            .gt('quantity_remaining', 0);

        if (isShared && catId != null) {
          query = query.eq('cukai_category_id', catId);
        } else {
          query = query.eq('product_id', entry.productId!);
        }

        final batchesRes = await query
            .order('request_date', ascending: true)
            .order('created_at', ascending: true);

        final batches = List<Map<String, dynamic>>.from(batchesRes);
        int totalAvailable = batches.fold<int>(0, (sum, b) => sum + (b['quantity_remaining'] as int));

        if (used + damaged > totalAvailable) {
          throw Exception('Stok pita cukai tidak mencukupi untuk $productName! Tersedia: ${NumberFormat('#,###').format(totalAvailable)} lembar, Diminta: ${NumberFormat('#,###').format(used + damaged)} lembar.');
        }

        int remainingUsed = used;
        int remainingDamaged = damaged;

        for (final b in batches) {
          if (remainingUsed == 0 && remainingDamaged == 0) break;

          final batchId = b['id'] as String;
          final available = b['quantity_remaining'] as int;

          final deductUsed = remainingUsed < available ? remainingUsed : available;
          final deductDamaged = remainingDamaged < (available - deductUsed) ? remainingDamaged : (available - deductUsed);

          if (deductUsed > 0 || deductDamaged > 0) {
            final alloc = _getMatchingAllocation(entry.productId!);
            await service.insert({
              'allocation_id': alloc?['id'],
              'factory_id': factoryId,
              'usage_date': WIB.toDateString(_usageDate),
              'used_amount': deductUsed,
              'damaged_amount': deductDamaged,
              'added_amount': 0,
              'product_id': entry.productId,
              'cukai_request_id': batchId,
              'notes': entry.notesController.text.isEmpty ? null : entry.notesController.text,
              'created_by': userId,
            });

            remainingUsed -= deductUsed;
            remainingDamaged -= deductDamaged;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pencatatan pemakaian cukai berhasil disimpan')),
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
      appBar: _buildAppBar(context, bg, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(isDark),
            const SizedBox(height: 16),
            _buildAllocationInfo(isDark),
            const SizedBox(height: 20),
            // Build entries list
            ..._entries.asMap().entries.map((item) => Column(
              children: [
                _buildEntryCard(isDark, item.value, item.key),
                const SizedBox(height: 20),
              ],
            )),
            _buildAddButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color bg, bool isDark) {
    return AppBar(
      backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
      leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
      title: Text('Catat Pemakaian', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pencatatan Pemakaian', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2)),
        const SizedBox(height: 6),
        Text('Lengkapi data penggunaan pita cukai', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14)),
      ],
    );
  }

  Widget _buildAllocationInfo(bool isDark) {
    if (_allocationList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('Tidak ada alokasi cukai aktif', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
      );
    }

    int quota = 0;
    int used = 0;
    int damaged = 0;
    for (final a in _allocationList) {
      quota += (a['quota'] as num?)?.toInt() ?? 0;
      used += (a['used'] as num?)?.toInt() ?? 0;
      damaged += (a['damaged'] as num?)?.toInt() ?? 0;
    }
    final remaining = quota - used - damaged;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _buildInfoChip('Kuota', NumberFormat('#,###').format(quota), AppTheme.primary, isDark),
          const SizedBox(width: 12),
          _buildInfoChip('Terpakai', NumberFormat('#,###').format(used), AppTheme.error, isDark),
          const SizedBox(width: 12),
          _buildInfoChip('Sisa', NumberFormat('#,###').format(remaining), const Color(0xFF10B981), isDark),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildEntryCard(bool isDark, _CukaiEntry entry, int index) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    // Product specifications
    Map<String, dynamic>? prod;
    if (entry.productId != null) {
      try {
        prod = _products.firstWhere((p) => p['id'] == entry.productId);
      } catch (_) {}
    }

    final alloc = entry.productId != null ? _getMatchingAllocation(entry.productId!) : null;
    final totalStamps = alloc != null ? (alloc['quota'] as num).toInt() - (alloc['used'] as num).toInt() - ((alloc['damaged'] as num?)?.toInt() ?? 0) : 0;
    final unaffixedStock = prod != null ? (prod['unaffixed_stock'] as num?)?.toInt() ?? 0 : 0;
    final usedVal = int.tryParse(entry.usedController.text) ?? 0;
    final damagedVal = int.tryParse(entry.damagedController.text) ?? 0;
    final finalStamps = totalStamps - usedVal - damagedVal;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), offset: const Offset(0, 6), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of the card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Data Pemakaian Cukai', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0) ...[
                  _buildDateField(isDark),
                  const SizedBox(height: 16),
                ],
                _buildProductDropdown(isDark, entry),
                const SizedBox(height: 16),
                
                if (prod != null) ...[
                  // Display Seri, Warna, Kode Personalisasi from Product (auto-filled, read-only)
                  Row(children: [
                    Expanded(child: _buildReadOnlyInput(isDark: isDark, label: 'Kode Personalisasi', value: prod['kode_personalisasi'] ?? '-')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildReadOnlyInput(isDark: isDark, label: 'Seri Pita Cukai', value: prod['seri'] ?? '-')),
                  ]),
                  const SizedBox(height: 12),
                  _buildReadOnlyInput(isDark: isDark, label: 'Warna Pita Cukai', value: prod['warna'] ?? '-'),
                  const SizedBox(height: 16),

                  if (alloc != null) ...[
                    _buildBatchStockRow(isDark: isDark, totalSticks: totalStamps),
                    const SizedBox(height: 8),
                    _buildProductStockRow(isDark: isDark, unaffixedStock: unaffixedStock),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildInputField(isDark: isDark, label: 'Pita Dipakai (lbr) *', hintText: 'Jml dipakai', controller: entry.usedController, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInputField(isDark: isDark, label: 'Pita Rusak (lbr)', hintText: 'Jml rusak', controller: entry.damagedController, keyboardType: TextInputType.number)),
                    ]),
                    if (usedVal > 0 || damagedVal > 0) ...[
                      const SizedBox(height: 16),
                      _buildFeedbackCard(isDark: isDark, totalSticks: totalStamps, usedVal: usedVal, damagedVal: damagedVal, finalStamps: finalStamps, unaffixedStock: unaffixedStock),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Alokasi pita cukai untuk produk ini tidak tersedia di gudang pabrik.\n(Harap hubungi Admin untuk konfigurasi alokasi)',
                            style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : AppTheme.surfaceContainerLow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : AppTheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.category_outlined, color: isDark ? Colors.white30 : AppTheme.outline, size: 32),
                        const SizedBox(height: 8),
                        Text('Silakan pilih produk terlebih dahulu', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildTextAreaField(isDark: isDark, label: 'Keterangan/Catatan', hintText: 'Tuliskan catatan tambahan...', controller: entry.notesController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDropdown(bool isDark, _CukaiEntry entry) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Produk Rokok', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
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
        icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white38 : AppTheme.outline),
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

  Widget _buildReadOnlyInput({required bool isDark, required String label, required String value}) {
    final fillColor = isDark ? const Color(0xFF1E293B) : AppTheme.surfaceContainerLow.withValues(alpha: 0.2);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(value, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildBatchStockRow({required bool isDark, required int totalSticks}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(Icons.inventory_2_outlined, color: Colors.green[600], size: 18),
          const SizedBox(width: 8),
          const Text('Stok Pita Cukai Tersedia:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        Text('${NumberFormat('#,###').format(totalSticks)} lembar', style: TextStyle(color: Colors.green[700], fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildProductStockRow({required bool isDark, required int unaffixedStock}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(Icons.inventory_outlined, color: Colors.blue[600], size: 18),
          const SizedBox(width: 8),
          const Text('Stok Rokok Belum Dilekati:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        Text('${NumberFormat('#,###').format(unaffixedStock)} kemasan', style: TextStyle(color: Colors.blue[700], fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildFeedbackCard({required bool isDark, required int totalSticks, required int usedVal, required int damagedVal, required int finalStamps, required int unaffixedStock}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryFixed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stok Pita Sebelum', style: TextStyle(fontSize: 12)),
              Text('${NumberFormat('#,###').format(totalSticks)} lembar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          if (usedVal > 0) ...[
            const Divider(height: 12, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pita Dipakai', style: TextStyle(fontSize: 12)),
                Text('- ${NumberFormat('#,###').format(usedVal)} lembar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ],
          if (damagedVal > 0) ...[
            const Divider(height: 12, color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pita Rusak/Cacat', style: TextStyle(fontSize: 12)),
                Text('- ${NumberFormat('#,###').format(damagedVal)} lembar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ],
          const Divider(height: 12, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sisa Stok Pita', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${NumberFormat('#,###').format(finalStamps)} lembar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: finalStamps < 0 ? Colors.red : Colors.green)),
            ],
          ),
          const Divider(height: 12, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sisa Rokok Belum Dilekati', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('${NumberFormat('#,###').format(unaffixedStock - usedVal)} kemasan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: (unaffixedStock - usedVal) < 0 ? Colors.red : Colors.blue)),
            ],
          ),
          const Divider(height: 12, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rokok Jadi Bertambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
               Text('+ ${NumberFormat('#,###').format(usedVal)} kemasan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Pencatatan', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd MMM yyyy').format(_usageDate), style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
                Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white38 : AppTheme.outline, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({required bool isDark, required String label, String? hintText, required TextEditingController controller, TextInputType? keyboardType}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
      ],
    );
  }

  Widget _buildTextAreaField({required bool isDark, required String label, required String hintText, required TextEditingController controller}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller, maxLines: 2,
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
      ],
    );
  }

  Widget _buildAddButton() {
    return OutlinedButton.icon(
      onPressed: _addEntry,
      icon: const Icon(Icons.add_circle_outline, size: 22),
      label: const Text('Tambah Produk/Cukai Baru'),
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
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Simpan Data Pemakaian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CukaiEntry {
  String? productId;
  String? cukaiRequestId;
  late final TextEditingController usedController;
  late final TextEditingController damagedController;
  late final TextEditingController notesController;

  _CukaiEntry({VoidCallback? onChanged}) {
    usedController = TextEditingController();
    damagedController = TextEditingController();
    notesController = TextEditingController();
    if (onChanged != null) {
      usedController.addListener(onChanged);
      damagedController.addListener(onChanged);
      notesController.addListener(onChanged);
    }
  }

  void dispose() {
    usedController.dispose();
    damagedController.dispose();
    notesController.dispose();
  }
}
