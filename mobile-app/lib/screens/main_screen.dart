import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'views/home_view.dart';
import 'views/history_view.dart';
import 'views/laporan_view.dart';
import 'views/profil_view.dart';
import 'production_form_screen.dart';
import 'cukai_form_screen.dart';
import 'keluar_form_screen.dart';
import 'pengajuan_cukai_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isFabOpen = false;
  late AnimationController _fabAnimController;
  late Animation<double> _fabRotation;

  final GlobalKey<HomeViewState> _homeKey = GlobalKey<HomeViewState>();
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      HomeView(
        key: _homeKey,
        onNavigateToHistory: () {
          setState(() => _selectedIndex = 1);
        },
      ),
      const HistoryView(),
      const LaporanView(),
      const ProfilView(),
    ];
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabRotation = Tween<double>(begin: 0.0, end: 0.375).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: _views,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
      return Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, -4),
              blurRadius: 24,
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomAppBar(
            color: navBg,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            elevation: 0,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.dashboard_rounded, 'Beranda', 0),
                  _buildNavItem(Icons.history_rounded, 'Riwayat', 1),
                  const SizedBox(width: 48),
                  _buildNavItem(Icons.analytics_outlined, 'Laporan', 2),
                  _buildNavItem(Icons.person_outline_rounded, 'Profil', 3),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.outline),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabRotation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleFAB,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Transform.rotate(
              angle: _fabRotation.value * 2 * 3.14159,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        );
      },
    );
  }

  void _toggleFAB() {
    // Check if user account is active
    final auth = context.read<AuthProvider>();
    if (auth.profile != null && !auth.profile!.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Akun Anda dinonaktifkan. Hubungi admin untuk mengaktifkan kembali.'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_isFabOpen) {
      _fabAnimController.reverse();
    } else {
      _fabAnimController.forward();
    }
    setState(() => _isFabOpen = !_isFabOpen);
    _showActionMenu(context);
  }

  void _showActionMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.outlineVariant.withValues(alpha: 0.3);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Aksi',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppTheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih tindakan yang ingin dilakukan',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _fabAnimController.reverse();
                        setState(() => _isFabOpen = false);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.outlineVariant.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: dividerColor, height: 1, thickness: 1),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildActionButton(
                      context: sheetContext,
                      isDark: isDark,
                      icon: Icons.unarchive_outlined,
                      iconColor: Colors.white,
                      gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1E40AF)],
                      accentColor: AppTheme.primary,
                      accentLabel: 'PRODUKSI',
                      title: 'Produksi Baru',
                      subtitle: 'Input data barang masuk dari area produksi ke gudang.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        _fabAnimController.reverse();
                        setState(() => _isFabOpen = false);
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionFormScreen()));
                        if (res == true) {
                          _homeKey.currentState?.loadDashboardData();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      context: sheetContext,
                      isDark: isDark,
                      icon: Icons.confirmation_number_outlined,
                      iconColor: Colors.white,
                      gradientColors: [const Color(0xFF10B981), const Color(0xFF047857)],
                      accentColor: AppTheme.secondary,
                      accentLabel: 'CUKAI',
                      title: 'Catat Cukai',
                      subtitle: 'Pindai dan catat pita cukai untuk barang siap jual.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        _fabAnimController.reverse();
                        setState(() => _isFabOpen = false);
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CukaiFormScreen()));
                        if (res == true) {
                          _homeKey.currentState?.loadDashboardData();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      context: sheetContext,
                      isDark: isDark,
                      icon: Icons.assignment_outlined,
                      iconColor: Colors.white,
                      gradientColors: [const Color(0xFF6366F1), const Color(0xFF312E81)],
                      accentColor: const Color(0xFF6366F1),
                      accentLabel: 'PENGAJUAN',
                      title: 'Ajukan Cukai',
                      subtitle: 'Buat permohonan penyediaan pita cukai baru.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        _fabAnimController.reverse();
                        setState(() => _isFabOpen = false);
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PengajuanCukaiScreen()));
                        if (res == true) {
                          _homeKey.currentState?.loadDashboardData();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      context: sheetContext,
                      isDark: isDark,
                      icon: Icons.shopping_cart_checkout_outlined,
                      iconColor: Colors.white,
                      gradientColors: [const Color(0xFFEF4444), const Color(0xFF991B1B)],
                      accentColor: AppTheme.error,
                      accentLabel: 'KELUAR',
                      title: 'Pengeluaran Barang',
                      subtitle: 'Proses pengiriman barang keluar atau transfer antar gudang.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        _fabAnimController.reverse();
                        setState(() => _isFabOpen = false);
                        final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const KeluarFormScreen()));
                        if (res == true) {
                          _homeKey.currentState?.loadDashboardData();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Reset FAB rotation when sheet is dismissed via swipe
      if (_isFabOpen) {
        _fabAnimController.reverse();
        setState(() => _isFabOpen = false);
      }
    });
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required Color accentColor,
    required String accentLabel,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF334155) : AppTheme.surfaceContainerLow;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            children: [
              // Gradient icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            accentLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : AppTheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}