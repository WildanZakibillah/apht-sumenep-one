import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../profile_detail_screen.dart';

class ProfilView extends StatefulWidget {
  const ProfilView({super.key});

  @override
  State<ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<ProfilView> {
  bool _isLoggingOut = false;
  Map<String, dynamic>? _factoryData;

  @override
  void initState() {
    super.initState();
    _loadFactoryData();
  }

  Future<void> _loadFactoryData() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return;

    final res = await Supabase.instance.client
        .from('factories')
        .select()
        .eq('id', factoryId)
        .maybeSingle();

    if (mounted && res != null) {
      setState(() => _factoryData = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.outlineVariant;

    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(bg, isDark),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(isDark, cardBg, cardBorder, profile),
              const SizedBox(height: 24),
              _buildSectionLabel('INFORMASI AKUN', isDark),
              const SizedBox(height: 8),
              _buildAccountInfoCard(isDark, cardBg, cardBorder, dividerColor, profile),
              const SizedBox(height: 24),
              _buildSectionLabel('INFORMASI PABRIK', isDark),
              const SizedBox(height: 8),
              _buildFactoryInfoCard(isDark, cardBg, cardBorder, dividerColor),
              const SizedBox(height: 24),
              _buildSectionLabel('PREFERENSI', isDark),
              const SizedBox(height: 8),
              _buildPreferensiCard(context, isDark, cardBg, cardBorder, dividerColor),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color bg, bool isDark) {
    return AppBar(
      backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0, automaticallyImplyLeading: false,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Profil', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        Text('Pengaturan Sistem & Akun', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 13)),
      ]),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1)),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0));
  }

  Widget _buildUserCard(bool isDark, Color cardBg, Color cardBorder, profile) {
    return InkWell(
      onTap: () {
        if (profile != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile, factoryData: _factoryData)));
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
        child: Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, size: 34, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile?.fullName ?? 'User', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(profile?.email ?? '', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(profile != null ? AppConstants.roleDisplayName(profile.role) : '', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 20),
        ]),
      ),
    );
  }

  Widget _buildAccountInfoCard(bool isDark, Color cardBg, Color cardBorder, Color divider, profile) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(children: [
        _buildInfoRow('Nama Lengkap', profile?.fullName ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Email', profile?.email ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Telepon', profile?.phone ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Role', profile != null ? AppConstants.roleDisplayName(profile.role) : '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Status', profile?.isActive == true ? 'Aktif' : 'Nonaktif', isDark, divider, hasBorder: false),
      ]),
    );
  }

  Widget _buildFactoryInfoCard(bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(children: [
        _buildInfoRow('Nama Pabrik', _factoryData?['name'] ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Kode', _factoryData?['code'] ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Golongan', _factoryData?['golongan'] ?? '-', isDark, divider, hasBorder: true),
        _buildInfoRow('Alamat', _factoryData?['address'] ?? '-', isDark, divider, hasBorder: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Status Pabrik', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.secondaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: _factoryData?['status'] == 'active' ? AppTheme.secondary : AppTheme.error, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_factoryData?['status'] == 'active' ? 'Aktif' : 'Nonaktif', style: TextStyle(color: _factoryData?['status'] == 'active' ? AppTheme.secondary : AppTheme.error, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, Color divider, {bool hasBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(border: hasBorder ? Border(bottom: BorderSide(color: divider)) : null),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14)),
        Flexible(child: Text(value, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _buildPreferensiCard(BuildContext context, bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(children: [
        _buildThemeToggleRow(context, isDark),
      ]),
    );
  }

  Widget _buildThemeToggleRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.primary, size: 20)),
          const SizedBox(width: 14),
          Text(isDark ? 'Mode Gelap' : 'Mode Terang', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
        Switch(
          value: AppTheme.isDarkMode.value,
          onChanged: (val) async => await AppTheme.toggleTheme(context),
          activeThumbColor: Colors.white, activeTrackColor: AppTheme.primary,
          inactiveThumbColor: Colors.white, inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
        ),
      ]),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoggingOut ? null : () async {
        setState(() => _isLoggingOut = true);
        final auth = context.read<AuthProvider>();
        await auth.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      },
      icon: _isLoggingOut ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout_rounded, size: 20),
      label: Text(_isLoggingOut ? 'Keluar...' : 'Keluar Aplikasi', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
