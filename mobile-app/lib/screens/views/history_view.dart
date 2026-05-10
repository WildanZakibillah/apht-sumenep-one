import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(),
              SizedBox(height: 24),
              _buildHistoryCard(
                icon: Icons.shopping_cart_outlined,
                iconColor: AppTheme.error,
                iconBgColor: AppTheme.errorContainer.withValues(alpha: 0.5),
                title: 'UD Sejahtera',
                value: 'Rp 21.000.000',
                date: '2026-01-06',
                statusText: 'Keluar',
                statusColor: AppTheme.error,
                statusBgColor: AppTheme.errorContainer,
              ),
              SizedBox(height: 16),
              _buildHistoryCard(
                icon: Icons.shopping_cart_outlined,
                iconColor: AppTheme.error,
                iconBgColor: AppTheme.errorContainer.withValues(alpha: 0.5),
                title: 'CV Maju Jaya',
                value: 'Rp 15.000.000',
                date: '2026-01-06',
                statusText: 'Keluar',
                statusColor: AppTheme.error,
                statusBgColor: AppTheme.errorContainer,
              ),
              SizedBox(height: 16),
              _buildHistoryCard(
                icon: Icons.confirmation_number_outlined,
                iconColor: AppTheme.tertiary,
                iconBgColor: AppTheme.tertiaryFixed.withValues(alpha: 0.5),
                title: 'Pemakaian Cukai',
                value: '-1.200 Pita',
                valueColor: AppTheme.error,
                date: '2026-01-05',
                statusText: 'Cukai',
                statusColor: AppTheme.tertiaryContainer,
                statusBgColor: AppTheme.tertiaryFixed,
              ),
              SizedBox(height: 16),
              _buildHistoryCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppTheme.secondary,
                iconBgColor: AppTheme.secondaryContainer.withValues(alpha: 0.5),
                title: 'Produksi Batch A',
                value: '+5.000 Box',
                valueColor: AppTheme.secondary,
                date: '2026-01-04',
                statusText: 'Produksi',
                statusColor: AppTheme.secondary,
                statusBgColor: AppTheme.secondaryContainer,
              ),
              SizedBox(height: 80), // Padding for Bottom Navigation
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
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

  Widget _buildHistoryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    Color? valueColor,
    required String date,
    required String statusText,
    required Color statusColor,
    required Color statusBgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 4),
            blurRadius: 20,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? AppTheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: AppTheme.outline,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}