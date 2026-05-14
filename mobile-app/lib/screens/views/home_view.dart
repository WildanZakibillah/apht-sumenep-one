import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HomeView extends StatelessWidget {
  final VoidCallback? onNavigateToHistory;

  const HomeView({super.key, this.onNavigateToHistory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          children: [
            _HeroCarousel(isDark: isDark),

            const SizedBox(height: 18),

            _buildStatsGrid(isDark),

            const SizedBox(height: 18),

            _buildReportCard(isDark),

            const SizedBox(height: 22),

            _buildRecentActivities(context, isDark),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF6F8FC),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budi Santoso',
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'Gudang 1 • Area Sentral',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 18),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // Hero Section Moved to _HeroCarousel

  Widget _buildStatsGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            title: 'Produksi',
            value: '11.400',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF4F46E5),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            title: 'Sisa Cukai',
            value: '300',
            icon: Icons.confirmation_number_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 14),

          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Bulanan',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Periode berjalan',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  isDark: isDark,
                  title: 'Produksi',
                  value: '11.400',
                  color: const Color(0xFF4F46E5),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildMiniStat(
                  isDark: isDark,
                  title: 'Keluar',
                  value: '14.400',
                  color: const Color(0xFF10B981),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildMiniStat(
                  isDark: isDark,
                  title: 'Sisa',
                  value: '300',
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Cetak Laporan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB),
                foregroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF374151),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required bool isDark,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Terkini',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
                if (onNavigateToHistory != null) {
                  onNavigateToHistory!();
                }
              },
              child: Text(
                'Lihat Semuanya',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildActivityCard(
          isDark: isDark,
          title: 'Barang Keluar',
          subtitle: 'SKU-99283 • 50 Unit',
          time: '09:12',
          icon: Icons.outbox_rounded,
          color: const Color(0xFF10B981),
        ),

        const SizedBox(height: 12),

        _buildActivityCard(
          isDark: isDark,
          title: 'Penggunaan Pita Cukai',
          subtitle: 'Batch-A12 • 200 Lembar',
          time: '08:45',
          icon: Icons.inventory_rounded,
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final bool isDark;
  const _HeroCarousel({required this.isDark});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildHeroSlide(
                widget.isDark,
                title: 'Total Pendapatan',
                value: 'Rp 36.000.000',
                icon: Icons.account_balance_wallet_rounded,
                bgIcon: Icons.payments_rounded,
                gradientStart: widget.isDark ? const Color(0xFF312E81) : const Color(0xFF4F46E5),
                gradientEnd: widget.isDark ? const Color(0xFF4338CA) : const Color(0xFF6366F1),
                shadowColor: const Color(0xFF4F46E5),
              ),
              _buildHeroSlide(
                widget.isDark,
                title: 'Total Pengeluaran',
                value: 'Rp 14.500.000',
                icon: Icons.trending_down_rounded,
                bgIcon: Icons.money_off_rounded,
                gradientStart: widget.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFDC2626),
                gradientEnd: widget.isDark ? const Color(0xFF991B1B) : const Color(0xFFEF4444),
                shadowColor: const Color(0xFFEF4444),
              ),
              _buildHeroSlide(
                widget.isDark,
                title: 'Saldo Kas',
                value: 'Rp 21.500.000',
                icon: Icons.savings_rounded,
                bgIcon: Icons.account_balance_rounded,
                gradientStart: widget.isDark ? const Color(0xFF064E3B) : const Color(0xFF059669),
                gradientEnd: widget.isDark ? const Color(0xFF065F46) : const Color(0xFF10B981),
                shadowColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primary
                    : AppTheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroSlide(
    bool isDark, {
    required String title,
    required String value,
    required IconData icon,
    required IconData bgIcon,
    required Color gradientStart,
    required Color gradientEnd,
    required Color shadowColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2), // small margin for pageview spacing
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 20,
            child: Icon(
              bgIcon,
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: Icon(
              icon,
              size: 70,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.82),
                      size: 15,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Update terakhir 08:00 WIB',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
