import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../account_info_screen.dart';
import '../factory_info_screen.dart';

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

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    await auth.ensureProfileLoaded();
    await _loadFactoryData();
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUserCard(isDark, cardBg, cardBorder, profile),
                const SizedBox(height: 24),
                _buildSectionLabel('INFORMASI', isDark),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
                  child: Column(children: [
                    _buildSettingRow(
                      isDark: isDark,
                      icon: Icons.person_outline_rounded,
                      iconColor: AppTheme.primary,
                      title: 'Informasi Akun',
                      subtitle: 'Detail data profil akun Anda',
                      onTap: () {
                        if (profile != null) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => AccountInfoScreen(profile: profile)));
                        }
                      },
                    ),
                    Divider(height: 1, color: dividerColor),
                    _buildSettingRow(
                      isDark: isDark,
                      icon: Icons.factory_outlined,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Informasi Pabrik',
                      subtitle: 'Detail data spesifikasi pabrik Anda',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FactoryInfoScreen(factoryData: _factoryData)));
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('PREFERENSI', isDark),
                const SizedBox(height: 8),
                _buildPreferensiCard(context, isDark, cardBg, cardBorder, dividerColor),
                const SizedBox(height: 24),
                _buildSectionLabel('TENTANG & BANTUAN', isDark),
                const SizedBox(height: 8),
                _buildAboutCard(isDark, cardBg, cardBorder, dividerColor),
                const SizedBox(height: 24),
                _buildLogoutButton(context),
                const SizedBox(height: 80),
              ],
            ),
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
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)],
        ),
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildUserCard(bool isDark, Color cardBg, Color cardBorder, profile) {
    return InkWell(
      onTap: () {
        if (profile != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AccountInfoScreen(profile: profile)));
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
        child: Row(children: [
          _buildAvatarWidget(profile?.avatarUrl, 64, isDark),
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

  // Info cards are now in separate screens

  Widget _buildPreferensiCard(BuildContext context, bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(children: [
        _buildThemeToggleRow(context, isDark),
        Divider(height: 1, color: divider),
        _buildSettingRow(
          isDark: isDark,
          icon: Icons.notifications_outlined,
          iconColor: const Color(0xFFF59E0B),
          title: 'Notifikasi',
          subtitle: 'Aktif',
          onTap: () {},
        ),
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

  Widget _buildSettingRow({required bool isDark, required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 20),
        ]),
      ),
    );
  }

  Widget _buildAboutCard(bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cardBorder)),
      child: Column(children: [
        _buildSettingRow(
          isDark: isDark,
          icon: Icons.info_outline_rounded,
          iconColor: AppTheme.primary,
          title: 'Tentang Aplikasi',
          subtitle: 'APHT Sumenep One v1.0.0',
          onTap: () => _showAboutDialog(context, isDark),
        ),
        Divider(height: 1, color: divider),
        _buildSettingRow(
          isDark: isDark,
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF10B981),
          title: 'Kebijakan Privasi',
          subtitle: 'Perlindungan data pengguna',
          onTap: () {},
        ),
        Divider(height: 1, color: divider),
        _buildSettingRow(
          isDark: isDark,
          icon: Icons.help_outline_rounded,
          iconColor: const Color(0xFF6366F1),
          title: 'Bantuan & Dukungan',
          subtitle: 'FAQ dan kontak support',
          onTap: () {},
        ),
      ]),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.factory_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text('APHT Sumenep One', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Aplikasi manajemen pabrik hasil tembakau untuk Asosiasi Pengusaha Hasil Tembakau (APHT) Kabupaten Sumenep.', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          _buildAboutRow(isDark, 'Versi', '1.0.0'),
          _buildAboutRow(isDark, 'Platform', 'Android & iOS'),
          _buildAboutRow(isDark, 'Developer', 'Tim APHT Sumenep'),
          _buildAboutRow(isDark, 'Tahun', '2025'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.outline, fontSize: 13)),
        Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _isLoggingOut ? null : () async {
        final nav = Navigator.of(context);
        final auth = context.read<AuthProvider>();
        setState(() => _isLoggingOut = true);
        await auth.logout();
        if (!mounted) return;
        nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
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
