import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/profile.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Profile profile;
  final Map<String, dynamic>? factoryData;

  const ProfileDetailScreen({super.key, required this.profile, this.factoryData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.outlineVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        title: Text('Detail Profil', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Avatar & Name
          Center(child: Column(children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(profile.fullName, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(AppConstants.roleDisplayName(profile.role), style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ])),
          const SizedBox(height: 32),

          // Personal Info
          _buildSection(isDark, cardBg, cardBorder, dividerColor, 'Informasi Pribadi', Icons.person_outline, [
            _InfoItem('Nama Lengkap', profile.fullName),
            _InfoItem('Email', profile.email),
            _InfoItem('Telepon', profile.phone ?? 'Belum diisi'),
            _InfoItem('Status Akun', profile.isActive ? 'Aktif' : 'Nonaktif'),
            _InfoItem('Bergabung', DateFormat('dd MMMM yyyy').format(profile.createdAt)),
            _InfoItem('Update Terakhir', DateFormat('dd MMMM yyyy, HH:mm').format(profile.updatedAt)),
          ]),
          const SizedBox(height: 20),

          // Factory Info
          if (factoryData != null)
            _buildSection(isDark, cardBg, cardBorder, dividerColor, 'Informasi Pabrik', Icons.factory_outlined, [
              _InfoItem('Nama Pabrik', factoryData!['name'] ?? '-'),
              _InfoItem('Kode Pabrik', factoryData!['code'] ?? '-'),
              _InfoItem('Golongan', factoryData!['golongan'] ?? '-'),
              _InfoItem('Alamat', factoryData!['address'] ?? '-'),
              _InfoItem('Status', (factoryData!['status'] as String?) == 'active' ? 'Aktif' : 'Nonaktif'),
            ]),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildSection(bool isDark, Color cardBg, Color cardBorder, Color dividerColor, String title, IconData icon, List<_InfoItem> items) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primary, size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
        Divider(height: 1, color: dividerColor),
        ...items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(border: !isLast ? Border(bottom: BorderSide(color: dividerColor)) : null),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 14)),
              const SizedBox(width: 16),
              Flexible(child: Text(item.value, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
