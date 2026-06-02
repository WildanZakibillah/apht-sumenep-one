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

  String _jenisPengajuan = 'AWAL';
  String _lokasiPenyediaan = 'KPPBC';
  String? _jenisHasilTembakau;
  final _kodePersonalisasiController = TextEditingController();
  final _seriController = TextEditingController();
  final _warnaController = TextEditingController();
  final _tarifCukaiController = TextEditingController();
  final _hjeController = TextEditingController();
  final _isiPerBksController = TextEditingController();
  final _jumlahLembarController = TextEditingController();

  List<Map<String, dynamic>> _productTypes = [];

  @override
  void initState() {
    super.initState();
    _loadProductTypes();
    _tarifCukaiController.addListener(_onCostFieldChanged);
    _jumlahLembarController.addListener(_onCostFieldChanged);
  }

  void _onCostFieldChanged() {
    setState(() {}); // Rebuild to update total cost display
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

  Future<void> _loadProductTypes() async {
    final res = await Supabase.instance.client.from('product_types').select('name, category');
    if (mounted) {
      // Deduplicate by name
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final item in res) {
        final name = item['name'] as String;
        if (!seen.contains(name)) {
          seen.add(name);
          unique.add(Map<String, dynamic>.from(item));
        }
      }
      setState(() {
        _productTypes = unique;
        if (_productTypes.isNotEmpty) {
          _jenisHasilTembakau = _productTypes.first['name'] as String;
        }
      });
    }
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
    if (_jenisHasilTembakau == null || _jenisHasilTembakau!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Pilih jenis hasil tembakau'), backgroundColor: AppTheme.error),
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
      final userId = auth.profile!.id;

      final now = WIB.now();
      final docNumber = 'CK-${now.millisecondsSinceEpoch % 100000}';

      final cukaiService = CukaiService();
      await cukaiService.insert({
        'doc_number': docNumber,
        'request_date': WIB.toDateString(_requestDate),
        'factory_id': factoryId,
        'jenis_pengajuan': _jenisPengajuan,
        'lokasi_penyediaan': _lokasiPenyediaan,
        'jenis_hasil_tembakau': _jenisHasilTembakau,
        'kode_personalisasi': _kodePersonalisasiController.text.isEmpty ? null : _kodePersonalisasiController.text,
        'seri': _seriController.text.isEmpty ? null : _seriController.text,
        'warna': _warnaController.text.isEmpty ? null : _warnaController.text,
        'tarif_cukai': double.tryParse(_tarifCukaiController.text.replaceAll('.', '').replaceAll(',', '.')),
        'hje': double.tryParse(_hjeController.text.replaceAll('.', '').replaceAll(',', '.')),
        'isi_per_bks': int.tryParse(_isiPerBksController.text),
        'jumlah_lembar': int.tryParse(_jumlahLembarController.text),
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
            _buildCard(isDark: isDark, title: 'Klasifikasi', icon: Icons.category_outlined, child: Column(children: [
              Row(children: [
                Expanded(child: _buildDropdown(isDark: isDark, label: 'Jenis Pengajuan', value: _jenisPengajuan, items: ['AWAL', 'TAMBAHAN', 'PELENGKAP'], onChanged: (v) => setState(() => _jenisPengajuan = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(isDark: isDark, label: 'Lokasi Penyediaan', value: _lokasiPenyediaan, items: ['KPPBC', 'KANWIL', 'LAINNYA'], onChanged: (v) => setState(() => _lokasiPenyediaan = v!))),
              ]),
              const SizedBox(height: 12),
              _buildDropdown(isDark: isDark, label: 'Jenis Hasil Tembakau', value: _jenisHasilTembakau, items: _productTypes.map((e) => e['name'] as String).toList(), onChanged: (v) => setState(() => _jenisHasilTembakau = v)),
            ])),
            const SizedBox(height: 16),
            _buildCard(isDark: isDark, title: 'Detail Pita Cukai', icon: Icons.confirmation_number_outlined, child: Column(children: [
              Row(children: [
                Expanded(child: _buildInput(isDark: isDark, label: 'Kode Personalisasi', controller: _kodePersonalisasiController)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput(isDark: isDark, label: 'Seri', controller: _seriController)),
              ]),
              const SizedBox(height: 12),
              _buildInput(isDark: isDark, label: 'Warna', controller: _warnaController),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInput(isDark: isDark, label: 'Tarif Cukai (Rp)', controller: _tarifCukaiController, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput(isDark: isDark, label: 'HJE (Rp)', controller: _hjeController, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInput(isDark: isDark, label: 'Isi/Bks', controller: _isiPerBksController, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput(isDark: isDark, label: 'Jumlah Lembar', controller: _jumlahLembarController, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              _buildTotalCostDisplay(isDark),
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

  Widget _buildDropdown({required bool isDark, required String label, String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        hint: Text('Pilih', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline)),
        isExpanded: true,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
        icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white38 : AppTheme.outline),
        decoration: InputDecoration(
          filled: true, fillColor: fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }

  Widget _buildInput({required bool isDark, required String label, required TextEditingController controller, TextInputType? keyboardType}) {
    final fillColor = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppTheme.outlineVariant;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintStyle: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline),
          filled: true, fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
        ),
      ),
    ]);
  }

  Widget _buildTotalCostDisplay(bool isDark) {
    final tarif = double.tryParse(_tarifCukaiController.text.replaceAll('.', '').replaceAll(',', '.')) ?? 0;
    final lembar = int.tryParse(_jumlahLembarController.text) ?? 0;
    final totalCost = tarif * lembar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: totalCost > 0
            ? AppTheme.primary.withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: totalCost > 0 ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total Biaya Penebusan Cukai', style: TextStyle(color: totalCost > 0 ? AppTheme.primary : (isDark ? Colors.white54 : AppTheme.onSurfaceVariant), fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          totalCost > 0 ? 'Rp ${NumberFormat('#,###').format(totalCost)}' : 'Rp 0',
          style: TextStyle(color: totalCost > 0 ? AppTheme.primary : (isDark ? Colors.white38 : AppTheme.outline), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        if (totalCost > 0) ...[
          const SizedBox(height: 4),
          Text('${NumberFormat('#,###').format(lembar)} lembar × Rp ${NumberFormat('#,###').format(tarif)}/lembar', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ]),
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
            : const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
