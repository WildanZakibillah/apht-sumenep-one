import 'package:flutter/material.dart';
import '../core/theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22),
            tooltip: 'Tandai semua dibaca',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildDateHeader(isDark, 'Hari Ini'),
          _buildNotificationItem(
            isDark: isDark,
            title: 'Pengajuan Cukai Disetujui',
            message: 'Pengajuan 1.000 Pita Cukai untuk Gudang 1 telah disetujui oleh admin pusat.',
            time: '10:45 WIB',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF10B981),
            isUnread: true,
          ),
          _buildNotificationItem(
            isDark: isDark,
            title: 'Peringatan Sisa Cukai',
            message: 'Sisa Pita Cukai SKT di Gudang 1 tersisa kurang dari 500 lembar. Segera lakukan pengajuan.',
            time: '08:15 WIB',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF59E0B),
            isUnread: true,
          ),
          _buildDateHeader(isDark, 'Kemarin'),
          _buildNotificationItem(
            isDark: isDark,
            title: 'Laporan Otomatis Dibuat',
            message: 'Laporan Rekapitulasi Produksi & Cukai untuk bulan berjalan telah di-generate.',
            time: '18:00 WIB',
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF3B82F6),
            isUnread: false,
          ),
          _buildNotificationItem(
            isDark: isDark,
            title: 'Barang Keluar: UD Sejahtera',
            message: 'Surat Jalan No. SJ-99283 telah diterbitkan. 50 Unit barang telah dikirim.',
            time: '14:20 WIB',
            icon: Icons.local_shipping_outlined,
            iconColor: AppTheme.primary,
            isUnread: false,
          ),
          _buildNotificationItem(
            isDark: isDark,
            title: 'Produksi Selesai',
            message: 'Batch Produksi A (SKT) sebanyak 5.000 unit telah berhasil diselesaikan dan masuk ke gudang.',
            time: '11:00 WIB',
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF4F46E5),
            isUnread: false,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateHeader(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required bool isDark,
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required bool isUnread,
  }) {
    final bgColor = isDark 
        ? (isUnread ? const Color(0xFF1E293B) : Colors.transparent)
        : (isUnread ? AppTheme.primary.withValues(alpha: 0.04) : Colors.transparent);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  if (isUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.onSurface,
                              fontSize: 15,
                              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : AppTheme.outline,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: TextStyle(
                        color: isDark 
                            ? (isUnread ? Colors.white70 : Colors.white54)
                            : (isUnread ? AppTheme.onSurfaceVariant : AppTheme.outline),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
