import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../services/cukai_usage_service.dart';

class CukaiFormScreen extends StatefulWidget {
  const CukaiFormScreen({super.key});

  @override
  State<CukaiFormScreen> createState() => _CukaiFormScreenState();
}

class _CukaiFormScreenState extends State<CukaiFormScreen> {
  bool _isLoading = false;
  DateTime _usageDate = DateTime.now();
  final _usedController = TextEditingController();
  final _addedController = TextEditingController();
  final _notesController = TextEditingController();

  // Allocation info
  Map<String, dynamic>? _allocation;

  @override
  void initState() {
    super.initState();
    _loadAllocation();
  }

  @override
  void dispose() {
    _usedController.dispose();
    _addedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAllocation() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return;

    final res = await Supabase.instance.client
        .from('cukai_allocations')
        .select()
        .eq('factory_id', factoryId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (mounted) setState(() => _allocation = res);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _usageDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _usageDate = picked);
  }

  Future<void> _submitData() async {
    final used = int.tryParse(_usedController.text) ?? 0;
    final added = int.tryParse(_addedController.text) ?? 0;

    if (used == 0 && added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Isi pemakaian atau pita tambahan'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_allocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Tidak ada alokasi cukai ditemukan untuk pabrik ini'), backgroundColor: AppTheme.error),
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

      final service = CukaiUsageService();
      await service.insert({
        'allocation_id': _allocation!['id'],
        'factory_id': factoryId,
        'usage_date': _usageDate.toIso8601String().split('T').first,
        'used_amount': used,
        'added_amount': added,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'created_by': userId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pencatatan cukai berhasil disimpan')),
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
            const SizedBox(height: 16),
            _buildFormCard(isDark),
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
    if (_allocation == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Text('Tidak ada alokasi cukai aktif', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
      );
    }

    final quota = _allocation!['quota'] as int;
    final used = _allocation!['used'] as int;
    final remaining = quota - used - ((_allocation!['damaged'] as int?) ?? 0);

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
            Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Form Pemakaian', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          _buildDateField(isDark),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Pemakaian Hari ini (-)', hintText: '0', controller: _usedController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildInputField(isDark: isDark, label: 'Pita Tambahan (+) Opsional', hintText: '0', controller: _addedController, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTextAreaField(isDark: isDark, label: 'Keterangan/Catatan', hintText: 'Tuliskan alasan pemakaian pita...', controller: _notesController),
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
          controller: controller, maxLines: 4,
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
