import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../login_screen.dart';

class ProfilView extends StatelessWidget {
  const ProfilView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AppTheme.outlineVariant;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(bg, isDark),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(isDark, cardBg, cardBorder),
              const SizedBox(height: 24),
              _buildSectionLabel('INFORMASI GUDANG', isDark),
              const SizedBox(height: 8),
              _buildInfoCard(isDark, cardBg, cardBorder, dividerColor),
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
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Pengaturan Sistem & Akun',
            style: TextStyle(
              color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppTheme.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? Colors.white38 : AppTheme.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildUserCard(bool isDark, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budi Santoso',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin Utama Gudang',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Lokasi Gudang', 'Gudang 1', isDark, divider, hasBorder: true),
          _buildInfoRow('Alamat', 'Jl. Industri Raya 45', isDark, divider, hasBorder: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status Sistem',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, Color divider, {bool hasBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: hasBorder ? Border(bottom: BorderSide(color: divider)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.onSurface,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferensiCard(BuildContext context, bool isDark, Color cardBg, Color cardBorder, Color divider) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPrefRow('Pengaturan Akun', Icons.manage_accounts_outlined, isDark, divider, hasBorder: true),
          _buildPrefRow('Pusat Bantuan', Icons.help_outline_rounded, isDark, divider, hasBorder: true),
          _buildThemeToggleRow(context, isDark),
        ],
      ),
    );
  }

  Widget _buildThemeToggleRow(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                isDark ? 'Mode Gelap' : 'Mode Terang',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: AppTheme.isDarkMode.value,
            onChanged: (val) async {
              await AppTheme.toggleTheme(context);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildPrefRow(String title, IconData icon, bool isDark, Color divider, {bool hasBorder = false}) {
    return InkWell(
      onTap: () {},
      borderRadius: hasBorder ? null : BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: hasBorder ? Border(bottom: BorderSide(color: divider)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : AppTheme.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      icon: const Icon(Icons.logout_rounded, size: 20),
      label: const Text(
        'Keluar Aplikasi',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.error,
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}