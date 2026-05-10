import 'package:flutter/material.dart';
import '../core/theme.dart';
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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const HomeView(),
    const HistoryView(),
    const LaporanView(),
    const ProfilView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 24,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomAppBar(
          color: AppTheme.surface,
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
                const SizedBox(width: 48), // Space for FAB
                _buildNavItem(Icons.analytics_outlined, 'Laporan', 2),
                _buildNavItem(Icons.person_outline_rounded, 'Profil', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primary : AppTheme.outline,
          ),
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
    return FloatingActionButton(
      onPressed: () => _showActionMenu(context),
      backgroundColor: AppTheme.primaryContainer,
      foregroundColor: Colors.white, // Menyesuaikan jika ingin ikon putih
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: AppTheme.surface, width: 4),
      ),
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Clean Header (Tanpa Background Ungu)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Aksi',
                            style: TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih tindakan yang ingin dilakukan',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.outlineVariant.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Garis pemisah halus (opsional agar lebih rapi)
              Divider(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                height: 1,
                thickness: 1,
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.unarchive_outlined,
                      iconColor: AppTheme.onPrimaryContainer,
                      iconBgColor: AppTheme.primaryContainer,
                      accentColor: AppTheme.primary,
                      accentLabel: 'PRODUKSI',
                      title: 'Produksi Baru',
                      subtitle: 'Input data barang masuk dari area produksi ke gudang.',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProductionFormScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      icon: Icons.confirmation_number_outlined,
                      iconColor: AppTheme.onSecondaryContainer,
                      iconBgColor: AppTheme.secondaryContainer,
                      accentColor: AppTheme.secondary,
                      accentLabel: 'CUKAI',
                      title: 'Catat Cukai',
                      subtitle: 'Pindai dan catat pita cukai untuk barang siap jual.',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CukaiFormScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      icon: Icons.assignment_outlined,
                      iconColor: const Color(0xFF1E3A8A),
                      iconBgColor: const Color(0xFFE0E7FF),
                      accentColor: const Color(0xFF1E3A8A),
                      accentLabel: 'PENGAJUAN',
                      title: 'Ajukan Cukai',
                      subtitle: 'Buat permohonan penyediaan pita cukai baru.',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengajuanCukaiScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildActionButton(
                      icon: Icons.shopping_cart_checkout_outlined,
                      iconColor: AppTheme.onErrorContainer,
                      iconBgColor: AppTheme.errorContainer,
                      accentColor: AppTheme.error,
                      accentLabel: 'KELUAR',
                      title: 'Pengeluaran Barang',
                      subtitle: 'Proses pengiriman barang keluar atau transfer antar gudang.',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KeluarFormScreen(),
                          ),
                        );
                      },
                    ),
                    // Safe area padding
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color accentColor,
    required String accentLabel,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.18),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
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
                        color: AppTheme.onSurfaceVariant,
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
                color: AppTheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}