import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/cukai_service.dart';
import '../utils/wib_helper.dart';

class PengajuanCukaiScreen extends StatefulWidget {
  const PengajuanCukaiScreen({super.key});

  @override
  State<PengajuanCukaiScreen> createState() => _PengajuanCukaiScreenState();
}

class _PengajuanCukaiScreenState extends State<PengajuanCukaiScreen> {
  bool _isLoading = false;
  DateTime _requestDate = WIB.now();

  String? _jenisHasilTembakau;
  final _kodePersonalisasiController = TextEditingController();
  final _seriController = TextEditingController();
  final _warnaController = TextEditingController();
  final _tarifCukaiController = TextEditingController();
  final _hjeController = TextEditingController();
  final _isiPerBksController = TextEditingController();
  final _jumlahLembarController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  String? _selectedProductId;
  String? _cukaiCategoryId;
  String? _cukaiCategoryName;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _kodePersonalisasiController.dispose();
    _seriController.dispose();
    _warnaController.dispose();
    _tarifCukaiController.dispose();
    _hjeController.dispose();
    _isiPerBksController.dispose();
    _jumlahLembarController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final factoryId = auth.profile?.factoryId;
      if (factoryId == null) return;

      final res = await Supabase.instance.client
          .from('cigarettes')
          .select('*, brands(name), cukai_categories(*)')
          .eq('factory_id', factoryId);

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(res);
          if (_products.isNotEmpty) {
            _selectedProductId = _products.first['id'] as String;
            _autoFillProductDetails(_products.first);
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _autoFillProductDetails(Map<String, dynamic> product) {
    final cat = product['cukai_categories'] as Map<String, dynamic>?;
    _cukaiCategoryId = cat != null ? (cat['id'] as String?) : null;
    _cukaiCategoryName = cat != null ? (cat['name'] as String?) : null;
    _hjeController.text = NumberFormat('#,###').format(cat != null ? (cat['hje'] ?? 0) : (product['hje'] ?? 0));
    _tarifCukaiController.text = NumberFormat('#,###').format(cat != null ? (cat['tarif_cukai'] ?? 0) : (product['excise_rate'] ?? 0));
    _isiPerBksController.text = (cat != null ? (cat['isi_per_bungkus'] ?? 12) : (product['sticks_per_pack'] ?? 12)).toString();
    _jenisHasilTembakau = cat != null ? (cat['jenis_ht'] ?? '') : '';
    _kodePersonalisasiController.text = product['kode_personalisasi'] ?? '';
    _seriController.text = product['seri'] ?? '';
    _warnaController.text = product['warna'] ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _requestDate = picked);
  }

  Future<void> _submitData() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Pilih produk rokok'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_cukaiCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Produk ini belum memiliki Kategori Cukai. Silakan hubungi Super Admin.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final jumlahLembar = int.tryParse(_jumlahLembarController.text) ?? 0;
    if (jumlahLembar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Jumlah lembar harus lebih dari 0'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated || auth.profile?.factoryId == null) {
        throw Exception("Sesi pengguna tidak valid atau tidak terkait pabrik");
      }
      final factoryId = auth.profile!.factoryId!;

      final client = Supabase.instance.client;

      // 1. Fetch total allocation quota and used (approved) amount for this category
      final allocsRes = await client
          .from('cukai_allocations')
          .select('quota, used')
          .eq('factory_id', factoryId)
          .eq('cukai_category_id', _cukaiCategoryId!);
      int totalQuota = 0;
      int totalUsed = 0;
      for (final a in allocsRes) {
        totalQuota += (a['quota'] as num?)?.toInt() ?? 0;
        totalUsed += (a['used'] as num?)?.toInt() ?? 0;
      }

      // 2. Fetch total pending request sheets for this category
      final pendingRes = await client
          .from('cukai_requests')
          .select('jumlah_lembar')
          .eq('factory_id', factoryId)
          .eq('cukai_category_id', _cukaiCategoryId!)
          .eq('status', 'pending');
      int totalPending = 0;
      for (final r in pendingRes) {
        totalPending += (r['jumlah_lembar'] as num?)?.toInt() ?? 0;
      }

      final sisaAlokasi = totalQuota - totalUsed - totalPending;

      if (jumlahLembar > sisaAlokasi) {
        setState(() => _isLoading = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Batas Kuota Terlampaui', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('Jumlah pengajuan (${NumberFormat('#,###').format(jumlahLembar)} lembar) melebihi sisa alokasi kuota kategori ini (${NumberFormat('#,###').format(sisaAlokasi)} lembar).'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memvalidasi alokasi: $e'), backgroundColor: AppTheme.error),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin mengirim pengajuan pita cukai sebanyak ${NumberFormat('#,###').format(jumlahLembar)} lembar ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Kirim'),
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
 
      final now = WIB.now();
      final docNumber = 'CK-${now.millisecondsSinceEpoch % 100000}';
 
      final cukaiService = CukaiService();
      await cukaiService.insert({
        'doc_number': docNumber,
        'request_date': WIB.toDateString(_requestDate),
        'factory_id': factoryId,
        'product_id': _selectedProductId,
        'cukai_category_id': _cukaiCategoryId,
        'jenis_pengajuan': 'AWAL',
        'lokasi_penyediaan': 'KPPBC',
        'jenis_hasil_tembakau': _jenisHasilTembakau,
        'kode_personalisasi': _kodePersonalisasiController.text.isEmpty ? null : _kodePersonalisasiController.text,
        'seri': _seriController.text.isEmpty ? null : _seriController.text,
        'warna': _warnaController.text.isEmpty ? null : _warnaController.text,
        'tarif_cukai': double.tryParse(_tarifCukaiController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        'hje': double.tryParse(_hjeController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0,
        'isi_per_bks': int.tryParse(_isiPerBksController.text) ?? 0,
        'jumlah_lembar': jumlahLembar,
        'status': 'pending',
        'created_by': userId,
      });
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: AppTheme.error),
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
        backgroundColor: bg, scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        centerTitle: true,
        title: Text('Form Pengajuan', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Permohonan Pita Cukai', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Text('Lengkapi data di bawah untuk pengajuan baru', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 24),
            _buildCard(isDark: isDark, title: 'Informasi Dokumen', icon: Icons.assignment_outlined, child: Column(children: [
              _buildDateField(isDark),
            ])),
            const SizedBox(height: 16),
            _buildCard(isDark: isDark, title: 'Klasifikasi & Produk', icon: Icons.category_outlined, child: Column(children: [
              _buildProductDropdown(isDark),
              if (_cukaiCategoryName != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori Cukai:', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$_cukaiCategoryName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Sifat: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            (() {
                              final p = _products.firstWhere((prod) => prod['id'] == _selectedProductId, orElse: () => <String, dynamic>{});
                              return (p['cukai_categories']?['is_shared'] ?? true) ? 'Shared (Boleh Dipakai Bersama)' : 'Eksklusif';
                            })(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedProductId != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Peringatan: Produk ini belum memiliki Kategori Cukai. Silakan hubungi Super Admin.',
                          style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ])),
            const SizedBox(height: 16),
            _buildCard(isDark: isDark, title: 'Detail Pita Cukai', icon: Icons.confirmation_number_outlined, child: Column(children: [
              Row(children: [
                Expanded(child: _buildInput(isDark: isDark, label: 'Kode Personalisasi • Otomatis', controller: _kodePersonalisasiController, enabled: false)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput(isDark: isDark, label: 'Seri • Otomatis', controller: _seriController, enabled: false)),
              ]),
              const SizedBox(height: 12),
              _buildInput(isDark: isDark, label: 'Warna • Otomatis', controller: _warnaController, enabled: false),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInput(isDark: isDark, label: 'Jenis HT • Otomatis', controller: TextEditingController(text: _jenisHasilTembakau ?? '-'), enabled: false)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput(isDark: isDark, label: 'Jumlah Lembar *', controller: _jumlahLembarController, keyboardType: TextInputType.number)),
              ]),
            ])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Pengajuan akan diverifikasi oleh admin APHT.', style: TextStyle(color: Colors.amber[800], fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, isDark),
    );
  }

  Widget _buildCard({required bool isDark, required String title, required IconData icon, required Widget child}) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _buildDateField(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Tanggal Pengajuan', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      InkWell(
        onTap: _pickDate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: fillColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('dd MMM yyyy').format(_requestDate), style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500)),
            Icon(Icons.calendar_month_outlined, color: isDark ? Colors.white38 : AppTheme.outline, size: 18),
          ]),
        ),
      ),
    ]);
  }



  Widget _buildInput({required bool isDark, required String label, required TextEditingController controller, TextInputType? keyboardType, bool enabled = true}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType, enabled: enabled,
        style: TextStyle(color: enabled ? (isDark ? Colors.white : AppTheme.onSurface) : (isDark ? Colors.white30 : AppTheme.outline), fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          filled: true, fillColor: enabled ? fillColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white10 : AppTheme.outlineVariant.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        ),
      ),
    ]);
  }

  Widget _buildProductDropdown(bool isDark) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Produk Rokok', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: _selectedProductId,
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
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _selectedProductId = v;
              final product = _products.firstWhere((p) => p['id'] == v);
              _autoFillProductDetails(product);
            });
          }
        },
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
            : const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
