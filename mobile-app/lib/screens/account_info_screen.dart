import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../models/profile.dart';

class AccountInfoScreen extends StatelessWidget {
  final Profile profile;
  const AccountInfoScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.07) : AppTheme.outlineVariant;
    final isActive = profile.isActive;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        title: Text('Informasi Akun', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Nama Lengkap', profile.fullName, isDark, dividerColor, true),
                  _buildDetailRow('Email', profile.email, isDark, dividerColor, true),
                  _buildDetailRow('Telepon', profile.phone ?? '-', isDark, dividerColor, true),
                  _buildDetailRow('Role / Peran', AppConstants.roleDisplayName(profile.role), isDark, dividerColor, true),
                  _buildDetailRow('Bergabung', DateFormat('dd MMMM yyyy').format(profile.createdAt), isDark, dividerColor, true),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status Akun', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 7, height: 7, decoration: BoxDecoration(color: isActive ? const Color(0xFF10B981) : AppTheme.error, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(color: isActive ? const Color(0xFF10B981) : AppTheme.error, fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark, Color divider, bool hasBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(border: hasBorder ? Border(bottom: BorderSide(color: divider)) : null),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurface, fontSize: 14)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
