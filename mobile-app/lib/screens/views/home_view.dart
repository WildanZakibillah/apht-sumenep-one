import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../utils/wib_helper.dart';
import '../activity_detail_screen.dart';
import '../notification_screen.dart';
import '../profile_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/report_pdf_service.dart';

class HomeView extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  const HomeView({super.key, this.onNavigateToHistory});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Dashboard stats
  int _totalProduksi = 0;
  int _sisaCukai = 0;
  num _totalPendapatan = 0;
  num _totalPengeluaranCukai = 0;
  int _totalKeluar = 0;
  List<Map<String, dynamic>> _todayActivities = [];
  bool _isLoading = true;
  Map<String, dynamic>? _factoryData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initNotifications();
  }

  void _initNotifications() {
    final auth = context.read<AuthProvider>();
    final userId = auth.profile?.id;
    if (userId != null) {
      context.read<NotificationProvider>().init(userId);
    }
  }

  Future<void> _loadDashboardData() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final client = Supabase.instance.client;
    final now = WIB.now();
    final startOfMonth = WIB.toDateString(DateTime(now.year, now.month, 1));
    final today = WIB.toDateString(now);

    try {
      // Total produksi bulan ini (jumlah_isi)
      final prodRes = await client
          .from('productions')
          .select('jumlah_isi')
          .eq('factory_id', factoryId)
          .gte('doc_date', startOfMonth);
      int totalProd = 0;
      for (final r in prodRes) {
        totalProd += (r['jumlah_isi'] as int?) ?? 0;
      }

      // Sisa cukai
      final cukaiRes = await client
          .from('cukai_allocations')
          .select('quota, used, damaged')
          .eq('factory_id', factoryId);
      int sisaCukai = 0;
      for (final r in cukaiRes) {
        sisaCukai += ((r['quota'] as int) - (r['used'] as int) - ((r['damaged'] as int?) ?? 0));
      }

      // Total pendapatan (outgoing_goods total_value bulan ini)
      final outRes = await client
          .from('outgoing_goods')
          .select('total_value, volume')
          .eq('factory_id', factoryId)
          .gte('transaction_date', startOfMonth);
      num totalPendapatan = 0;
      int totalKeluar = 0;
      for (final r in outRes) {
        totalPendapatan += (r['total_value'] as num?) ?? 0;
        totalKeluar += (r['volume'] as int?) ?? 0;
      }

      // Total pengeluaran cukai (tarif_cukai * jumlah_lembar from cukai_requests APPROVED only)
      final cukaiReqRes = await client
          .from('cukai_requests')
          .select('tarif_cukai, jumlah_lembar')
          .eq('factory_id', factoryId)
          .eq('status', 'approved')
          .gte('request_date', startOfMonth);
      num totalPengeluaranCukai = 0;
      for (final r in cukaiReqRes) {
        final tarif = (r['tarif_cukai'] as num?) ?? 0;
        final lembar = (r['jumlah_lembar'] as int?) ?? 0;
        totalPengeluaranCukai += tarif * lembar;
      }

      // Today's activities
      final todayActivities = <Map<String, dynamic>>[];

      final todayProd = await client
          .from('productions')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', '${today}T00:00:00')
          .order('created_at', ascending: false);
      for (final p in todayProd) {
        final hje = (p['hje'] as num?) ?? 0;
        final jumlahIsi = (p['jumlah_isi'] as int?) ?? 0;
        final totalNilai = hje * jumlahIsi;
        todayActivities.add({
          'title': 'Produksi ${p['merek']} (${p['jenis']})',
          'subtitle': '+${NumberFormat('#,###').format(jumlahIsi)} ${p['satuan']}',
          'time': DateFormat('HH:mm').format(WIB.parse(p['created_at'])),
          'date': DateFormat('dd MMM yyyy, HH:mm').format(WIB.parse(p['created_at'])),
          'icon': Icons.inventory_2_outlined,
          'color': const Color(0xFF10B981),
          'type': 'Produksi',
          'details': <String, String>{
            'No. Dokumen': p['doc_number'] ?? '-',
            'Tanggal': p['doc_date'] ?? '-',
            'Merek': p['merek'] ?? '-',
            'Jenis': p['jenis'] ?? '-',
            'HJE': 'Rp ${NumberFormat('#,###').format(hje)}',
            'Isi': '${p['isi']} ${p['satuan']}',
            'Jumlah Kemasan': NumberFormat('#,###').format(p['jumlah_kemasan']),
            'Jumlah Isi': NumberFormat('#,###').format(jumlahIsi),
            'Total Nilai Produksi': 'Rp ${NumberFormat('#,###').format(totalNilai)}',
          },
        });
      }

      final todayUsage = await client
          .from('cukai_usage_log')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', '${today}T00:00:00')
          .order('created_at', ascending: false);
      for (final u in todayUsage) {
        final used = u['used_amount'] as int;
        final added = u['added_amount'] as int;
        todayActivities.add({
          'title': 'Pemakaian Cukai${u['notes'] != null ? ' • ${u['notes']}' : ''}',
          'subtitle': '-$used lembar',
          'time': DateFormat('HH:mm').format(WIB.parse(u['created_at'])),
          'date': DateFormat('dd MMM yyyy, HH:mm').format(WIB.parse(u['created_at'])),
          'icon': Icons.confirmation_number_outlined,
          'color': const Color(0xFFF59E0B),
          'type': 'Cukai',
          'details': <String, String>{
            'Tanggal': u['usage_date'] ?? '-',
            'Pemakaian': '$used lembar',
            'Tambahan': '$added lembar',
            'Catatan': u['notes'] ?? '-',
          },
        });
      }

      final todayOut = await client
          .from('outgoing_goods')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', '${today}T00:00:00')
          .order('created_at', ascending: false);
      for (final o in todayOut) {
        final totalValue = (o['total_value'] as num?) ?? 0;
        todayActivities.add({
          'title': 'Keluar → ${o['customer_name']}',
          'subtitle': '${NumberFormat('#,###').format(o['volume'])} btg',
          'time': DateFormat('HH:mm').format(WIB.parse(o['created_at'])),
          'date': DateFormat('dd MMM yyyy, HH:mm').format(WIB.parse(o['created_at'])),
          'icon': Icons.shopping_cart_checkout_outlined,
          'color': const Color(0xFFEF4444),
          'type': 'Keluar',
          'details': <String, String>{
            'Tanggal': o['transaction_date'] ?? '-',
            'Pelanggan': o['customer_name'] ?? '-',
            'Volume': '${NumberFormat('#,###').format(o['volume'])} btg',
            'Total Nilai': 'Rp ${NumberFormat('#,###').format(totalValue)}',
            'Pembayaran': (o['payment_method'] as String?)?.toUpperCase() ?? '-',
          },
        });
      }

      // Fetch cukai requests today
      final todayReq = await client
          .from('cukai_requests')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', '${today}T00:00:00')
          .order('created_at', ascending: false);
      for (final r in todayReq) {
        final status = r['status'] as String;
        final statusLabel = status == 'approved' ? 'Disetujui' : status == 'rejected' ? 'Ditolak' : 'Pending';
        final tarif = (r['tarif_cukai'] as num?) ?? 0;
        final lembar = (r['jumlah_lembar'] as int?) ?? 0;
        todayActivities.add({
          'title': 'Pengajuan ${r['jenis_pengajuan']} • ${r['jenis_hasil_tembakau']}',
          'subtitle': statusLabel,
          'time': DateFormat('HH:mm').format(WIB.parse(r['created_at'])),
          'date': DateFormat('dd MMM yyyy, HH:mm').format(WIB.parse(r['created_at'])),
          'icon': Icons.assignment_outlined,
          'color': const Color(0xFF6366F1),
          'type': 'Pengajuan',
          'details': <String, String>{
            'No. Dokumen': r['doc_number'] ?? '-',
            'Tanggal': r['request_date'] ?? '-',
            'Jenis Pengajuan': r['jenis_pengajuan'] ?? '-',
            'Jenis Tembakau': r['jenis_hasil_tembakau'] ?? '-',
            'Jumlah Lembar': NumberFormat('#,###').format(lembar),
            'Tarif Cukai': 'Rp ${NumberFormat('#,###').format(tarif)}',
            'Total Nilai Cukai': 'Rp ${NumberFormat('#,###').format(tarif * lembar)}',
            'Status': statusLabel,
          },
        });
      }

      todayActivities.sort((a, b) => (b['time'] as String).compareTo(a['time'] as String));

      // Fetch factory info
      final factoryRes = await client
          .from('factories')
          .select()
          .eq('id', factoryId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _totalProduksi = totalProd;
          _sisaCukai = sisaCukai;
          _totalPendapatan = totalPendapatan;
          _totalPengeluaranCukai = totalPengeluaranCukai;
          _totalKeluar = totalKeluar;
          _todayActivities = todayActivities;
          _factoryData = factoryRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num value) {
    if (value >= 1000000000) return 'Rp ${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}Jt';
    return 'Rp ${NumberFormat('#,###').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context, isDark),
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          child: Column(
            children: [
              _HeroCarousel(
                isDark: isDark,
                totalPendapatan: _formatCurrency(_totalPendapatan),
                totalPengeluaran: _formatCurrency(_totalPengeluaranCukai),
                saldoKas: _formatCurrency(_totalPendapatan - _totalPengeluaranCukai),
              ),
              const SizedBox(height: 18),
              _buildStatsGrid(isDark),
              const SizedBox(height: 18),
              _buildReportCard(isDark),
              const SizedBox(height: 22),
              _buildRecentActivities(context, isDark),
            ],
          ),
        ),
      ),
    );
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

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC),
      elevation: 0, scrolledUnderElevation: 0, automaticallyImplyLeading: false, titleSpacing: 18,
      title: InkWell(
        onTap: () {
          if (profile != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileDetailScreen(profile: profile, factoryData: _factoryData)));
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatarWidget(profile?.avatarUrl, 44, isDark),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile?.fullName ?? 'User', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(profile != null ? _roleLabel(profile.role) : '', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 11.5)),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifProvider, _) {
            final unread = notifProvider.unreadCount;
            return Container(
              margin: const EdgeInsets.only(right: 18), width: 42, height: 42,
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Stack(
                children: [
                  IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())), icon: Icon(Icons.notifications_none_rounded, color: AppTheme.primary, size: 22)),
                  if (unread > 0)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(color: AppTheme.error, shape: BoxShape.circle, border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2)),
                        child: Center(child: Text(unread > 9 ? '9+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin_pabrik': return 'Admin Pabrik';
      case 'super_admin': return 'Super Admin';
      case 'direktur': return 'Direktur';
      default: return 'Staf Lapangan';
    }
  }

  Widget _buildStatsGrid(bool isDark) {
    return Row(children: [
      Expanded(child: _buildStatCard(isDark: isDark, title: 'Produksi', value: NumberFormat('#,###').format(_totalProduksi), icon: Icons.inventory_2_outlined, color: const Color(0xFF4F46E5))),
      const SizedBox(width: 14),
      Expanded(child: _buildStatCard(isDark: isDark, title: 'Sisa Cukai', value: NumberFormat('#,###').format(_sisaCukai), icon: Icons.confirmation_number_outlined, color: const Color(0xFFF59E0B))),
    ]);
  }

  Widget _buildStatCard({required bool isDark, required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 21)),
      ]),
    );
  }

  Widget _buildReportCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(children: [
        Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.75)])), child: const Icon(Icons.description_outlined, color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Laporan Bulanan', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text('Periode ${DateFormat('MMMM yyyy').format(DateTime.now())}', style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12)),
          ])),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(14)),
            child: IconButton(onPressed: _pickReportMonth, icon: Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20)),
          ),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _buildMiniStat(isDark: isDark, title: 'Produksi', value: NumberFormat('#,###').format(_totalProduksi), color: const Color(0xFF4F46E5))),
          const SizedBox(width: 10),
          Expanded(child: _buildMiniStat(isDark: isDark, title: 'Keluar', value: NumberFormat('#,###').format(_totalKeluar), color: const Color(0xFF10B981))),
          const SizedBox(width: 10),
          Expanded(child: _buildMiniStat(isDark: isDark, title: 'Sisa Cukai', value: NumberFormat('#,###').format(_sisaCukai), color: const Color(0xFFF59E0B))),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                foregroundColor: isDark ? Colors.white : const Color(0xFF374151),
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareReport,
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _pickReportMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // Reload data for selected month - for now just refresh
      _loadDashboardData();
    }
  }

  Future<void> _downloadReport() async {
    final pdfBytes = await _generateReportPdf();
    if (pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> _shareReport() async {
    final pdfBytes = await _generateReportPdf();
    if (pdfBytes == null) return;
    final month = DateFormat('MMMM-yyyy').format(DateTime.now());
    await ReportPdfService.sharePdf(pdfBytes, 'CK4_$month.pdf', text: 'Laporan CK-4 Periode $month');
  }

  Future<Uint8List?> _generateReportPdf() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return null;

    final client = Supabase.instance.client;
    final now = WIB.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final productions = await client
        .from('productions')
        .select()
        .eq('factory_id', factoryId)
        .gte('doc_date', WIB.toDateString(startOfMonth))
        .lte('doc_date', WIB.toDateString(endOfMonth))
        .order('doc_date');

    // Get factory info
    final factoryRes = await client
        .from('factories')
        .select()
        .eq('id', factoryId)
        .single();

    return ReportPdfService.generateCK4(
      productions: List<Map<String, dynamic>>.from(productions),
      factoryName: factoryRes['name'] ?? '-',
      factoryAddress: factoryRes['address'] ?? '-',
      nppbkc: factoryRes['code'] ?? '-',
      ownerName: auth.profile?.fullName ?? '-',
      periodStart: startOfMonth,
      periodEnd: endOfMonth,
      reportDate: now,
    );
  }

  Widget _buildMiniStat({required bool isDark, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Text(title, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }

  Widget _buildRecentActivities(BuildContext context, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Aktivitas Hari Ini', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
        TextButton(onPressed: widget.onNavigateToHistory, child: Text('Lihat Semua', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
      const SizedBox(height: 12),
      if (_isLoading)
        const Center(child: CircularProgressIndicator())
      else if (_todayActivities.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Center(child: Text('Belum ada aktivitas hari ini', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant))),
        )
      else
        ..._todayActivities.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildActivityCard(
            isDark: isDark,
            title: a['title'],
            subtitle: a['subtitle'],
            time: a['time'],
            icon: a['icon'],
            color: a['color'],
            context: context,
            date: a['date'],
            type: a['type'],
            details: a['details'] as Map<String, String>?,
          ),
        )),
    ]);
  }

  Widget _buildActivityCard({required bool isDark, required String title, required String subtitle, required String time, required IconData icon, required Color color, required BuildContext context, String? date, String? type, Map<String, String>? details}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
            title: title,
            subtitle: '${type ?? ''} • ${date ?? time}',
            amount: subtitle,
            status: type ?? 'Aktivitas',
            date: date ?? time,
            icon: icon,
            color: color,
            details: details ?? {'Waktu': time, 'Detail': subtitle},
          )));
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03))),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(10)),
              child: Text(time, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  final bool isDark;
  final String totalPendapatan;
  final String totalPengeluaran;
  final String saldoKas;
  const _HeroCarousel({required this.isDark, required this.totalPendapatan, required this.totalPengeluaran, required this.saldoKas});

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
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _currentPage = (_currentPage + 1) % 3;
      if (_pageController.hasClients) _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
    });
  }

  @override
  void dispose() { _pageController.dispose(); _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 190,
        child: PageView(
          controller: _pageController,
          onPageChanged: (p) => setState(() => _currentPage = p),
          children: [
            _buildSlide(title: 'Total Pendapatan', value: widget.totalPendapatan, icon: Icons.account_balance_wallet_rounded, bgIcon: Icons.payments_rounded, gradientStart: widget.isDark ? const Color(0xFF312E81) : const Color(0xFF4F46E5), gradientEnd: widget.isDark ? const Color(0xFF4338CA) : const Color(0xFF6366F1)),
            _buildSlide(title: 'Total Pengeluaran Cukai', value: widget.totalPengeluaran, icon: Icons.trending_down_rounded, bgIcon: Icons.money_off_rounded, gradientStart: widget.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFDC2626), gradientEnd: widget.isDark ? const Color(0xFF991B1B) : const Color(0xFFEF4444)),
            _buildSlide(title: 'Saldo Kas', value: widget.saldoKas, icon: Icons.savings_rounded, bgIcon: Icons.account_balance_rounded, gradientStart: widget.isDark ? const Color(0xFF064E3B) : const Color(0xFF059669), gradientEnd: widget.isDark ? const Color(0xFF065F46) : const Color(0xFF10B981)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300), margin: const EdgeInsets.symmetric(horizontal: 4), height: 6, width: _currentPage == i ? 24 : 6,
        decoration: BoxDecoration(color: _currentPage == i ? AppTheme.primary : AppTheme.outlineVariant.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
      ))),
    ]);
  }

  Widget _buildSlide({required String title, required String value, required IconData icon, required IconData bgIcon, required Color gradientStart, required Color gradientEnd}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gradientStart, gradientEnd])),
      child: Stack(children: [
        Positioned(bottom: -30, right: 20, child: Icon(bgIcon, size: 120, color: Colors.white.withValues(alpha: 0.06))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time_rounded, color: Colors.white.withValues(alpha: 0.82), size: 15),
              const SizedBox(width: 7),
              Text('Periode ${DateFormat('MMM yyyy').format(DateTime.now())}', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 11.5, fontWeight: FontWeight.w500)),
            ]),
          ),
        ]),
      ]),
    );
  }
}
