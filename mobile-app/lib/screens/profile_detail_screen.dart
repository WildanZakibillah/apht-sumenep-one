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
            _buildAvatarWidget(profile.avatarUrl, 100, isDark),
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
          if (factoryData != null) ...[
            _buildFactorySection(isDark, cardBg, cardBorder, dividerColor, factoryData!),
          ],

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl, double size, bool isDark) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(size, isDark),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          ),
        ),
      );
    }
    return _buildDefaultAvatar(size, isDark);
  }

  Widget _buildDefaultAvatar(double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)],
        ),
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.5),
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

  Widget _buildFactorySection(bool isDark, Color cardBg, Color cardBorder, Color dividerColor, Map<String, dynamic> data) {
    final logoUrl = data['logo_url'] as String?;
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final coordinatesText = (latitude != null && longitude != null) ? '$latitude, $longitude' : '-';

    final items = [
      _InfoItem('Nama Pabrik', data['name'] ?? '-'),
      _InfoItem('Kode Pabrik', data['code'] ?? '-'),
      _InfoItem('NPPBKC', data['nppbkc'] ?? '-'),
      _InfoItem('NIB', data['nib'] ?? '-'),
      _InfoItem('NPWP', data['npwp'] ?? '-'),
      _InfoItem('Pemilik', data['owner_name'] ?? '-'),
      _InfoItem('Direktur', data['director_name'] ?? '-'),
      _InfoItem('Golongan', data['golongan'] ?? '-'),
      _InfoItem('Telepon Pabrik', data['phone'] ?? '-'),
      _InfoItem('Email Pabrik', data['email'] ?? '-'),
      _InfoItem('Alamat', data['address'] ?? '-'),
      _InfoItem('Koordinat', coordinatesText),
      _InfoItem('Status', (data['status'] as String?) == 'active' ? 'Aktif' : 'Nonaktif'),
    ];

    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.factory_outlined, color: AppTheme.primary, size: 20)),
            const SizedBox(width: 12),
            Text('Informasi Pabrik', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ),
        Divider(height: 1, color: dividerColor),
        if (logoUrl != null && logoUrl.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.factory_outlined, color: AppTheme.primary, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: dividerColor),
        ],
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
