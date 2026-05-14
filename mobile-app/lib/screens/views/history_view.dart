import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../activity_detail_screen.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(isDark),
              SizedBox(height: 24),
              _buildActivityCard(
                isDark: isDark,
                title: 'UD Sejahtera',
                date: '2026-01-06',
                value: 'Rp 21.000.000',
                statusText: 'Keluar',
                icon: Icons.shopping_cart_outlined,
                iconColor: AppTheme.error,
                context: context,
              ),
              SizedBox(height: 16),
              _buildActivityCard(
                isDark: isDark,
                title: 'CV Maju Jaya',
                date: '2026-01-06',
                value: 'Rp 15.000.000',
                statusText: 'Keluar',
                icon: Icons.shopping_cart_outlined,
                iconColor: AppTheme.error,
                context: context,
              ),
              SizedBox(height: 16),
              _buildActivityCard(
                isDark: isDark,
                title: 'Pemakaian Cukai',
                date: '2026-01-05',
                value: '-1.200 Pita',
                valueColor: AppTheme.error,
                statusText: 'Cukai',
                icon: Icons.confirmation_number_outlined,
                iconColor: AppTheme.tertiary,
                context: context,
              ),
              SizedBox(height: 16),
              _buildActivityCard(
                isDark: isDark,
                title: 'Produksi Batch A',
                date: '2026-01-04',
                value: '+5.000 Box',
                valueColor: const Color(0xFF10B981),
                statusText: 'Produksi',
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF10B981),
                context: context,
              ),
              SizedBox(height: 80), // Padding for Bottom Navigation
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color backgroundColor) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Riwayat',
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
              ),
            ),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Cari Riwayat...',
                hintStyle: TextStyle(color: AppTheme.outline),
                prefixIcon: Icon(Icons.search, color: AppTheme.outline),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(Icons.filter_list_rounded),
            color: AppTheme.onPrimaryContainer,
            tooltip: 'Filter Bulan',
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required bool isDark,
    required String title,
    required String date,
    required String value,
    Color? valueColor,
    required String statusText,
    required IconData icon,
    required Color iconColor,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(
                title: title,
                subtitle: '$statusText • $date',
                amount: value,
                status: statusText,
                date: date,
                icon: icon,
                color: iconColor,
                details: const {
                  'No. Transaksi': 'TRX-99812-2026',
                  'Operator': 'Budi Santoso',
                  'Keterangan': 'Transaksi riwayat diselesaikan dengan status sukses.',
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: TextStyle(
                            color: valueColor ?? (isDark ? Colors.white : AppTheme.onSurface),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}