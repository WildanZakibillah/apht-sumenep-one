import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_pdf_service.dart';
import '../../utils/wib_helper.dart';
import '../activity_detail_screen.dart';

class LaporanView extends StatefulWidget {
  const LaporanView({super.key});

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  int _selectedTabIndex = 0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;

  // Stok data
  List<Map<String, dynamic>> _productions = [];

  // Actual cigarette inventory stocks
  List<Map<String, dynamic>> _cigarettes = [];
  int _totalStockPacks = 0;
  int _totalStockSticks = 0;

  // Cukai data
  List<Map<String, dynamic>> _cukaiUsages = [];
  int _sisaCukai = 0;

  // Keluar data
  List<Map<String, dynamic>> _outgoingGoods = [];
  int _totalKeluar = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final client = Supabase.instance.client;
    final startDate = WIB.toDateString(_selectedMonth);
    final endMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final endDate = WIB.toDateString(endMonth);

    try {
      // Productions
      final prodRes = await client
          .from('productions')
          .select()
          .eq('factory_id', factoryId)
          .gte('doc_date', startDate)
          .lt('doc_date', endDate)
          .order('created_at', ascending: false);


      // Cigarette actual stocks
      final cigsRes = await client
          .from('cigarettes')
          .select('*, brands(name)')
          .eq('factory_id', factoryId)
          .order('product_name', ascending: true);
      
      int totalStockPacks = 0;
      int totalStockSticks = 0;
      for (final c in cigsRes) {
        final stock = (c['stock'] as num?)?.toInt() ?? 0;
        final sticksPerPack = (c['sticks_per_pack'] as num?)?.toInt() ?? 12;
        totalStockPacks += stock;
        totalStockSticks += stock * sticksPerPack;
      }

      // Cukai
      final cukaiRes = await client
          .from('cukai_usage_log')
          .select()
          .eq('factory_id', factoryId)
          .gte('usage_date', startDate)
          .lt('usage_date', endDate)
          .order('created_at', ascending: false);

      final allocRes = await client
          .from('cukai_allocations')
          .select('quota, used, damaged')
          .eq('factory_id', factoryId);
      int sisaCukai = 0;
      for (final r in allocRes) {
        sisaCukai += ((r['quota'] as int) - (r['used'] as int) - ((r['damaged'] as int?) ?? 0));
      }

      // Outgoing (include cigarettes & brands details)
      final outRes = await client
          .from('outgoing_goods')
          .select('*, cigarettes(*, brands(*))')
          .eq('factory_id', factoryId)
          .gte('transaction_date', startDate)
          .lt('transaction_date', endDate)
          .order('created_at', ascending: false);
      int totalKeluar = 0;
      for (final o in outRes) {
        totalKeluar += (o['volume'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _productions = List<Map<String, dynamic>>.from(prodRes);
          _cukaiUsages = List<Map<String, dynamic>>.from(cukaiRes);
          _sisaCukai = sisaCukai;
          _outgoingGoods = List<Map<String, dynamic>>.from(outRes);
          _totalKeluar = totalKeluar;
          
          _cigarettes = List<Map<String, dynamic>>.from(cigsRes);
          _totalStockPacks = totalStockPacks;
          _totalStockSticks = totalStockSticks;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSegmentedControl(),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else
                  _buildContent(isDark),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color backgroundColor) {
    return AppBar(
      backgroundColor: backgroundColor, elevation: 0, scrolledUnderElevation: 0, automaticallyImplyLeading: false,
      title: Text('Laporan', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1)),
    );
  }


  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            DateFormat('MMM yyyy').format(_selectedMonth),
            style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _pickMonth,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(50)),
      child: Row(children: [
        _buildSegmentTab('Stok', 0),
        _buildSegmentTab('Cukai', 1),
        _buildSegmentTab('Keluar', 2),
      ]),
    );
  }

  Widget _buildSegmentTab(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            boxShadow: isSelected ? [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), offset: Offset(0, 2), blurRadius: 8)] : null,
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_selectedTabIndex) {
      case 0: return _buildStokContent(isDark);
      case 1: return _buildCukaiContent(isDark);
      case 2: return _buildKeluarContent(isDark);
      default: return const SizedBox();
    }
  }

  Future<Uint8List?> _generatePdf() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return null;

    final client = Supabase.instance.client;
    final startDate = WIB.toDateString(_selectedMonth);
    final endMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final endDate = WIB.toDateString(endMonth);

    final productions = await client
        .from('productions')
        .select()
        .eq('factory_id', factoryId)
        .gte('doc_date', startDate)
        .lte('doc_date', endDate)
        .order('doc_date');

    final factoryRes = await client.from('factories').select().eq('id', factoryId).single();

    return ReportPdfService.generateCK4(
      productions: List<Map<String, dynamic>>.from(productions),
      factoryName: factoryRes['name'] ?? '-',
      factoryAddress: factoryRes['address'] ?? '-',
      nppbkc: factoryRes['code'] ?? '-',
      ownerName: auth.profile?.fullName ?? '-',
      periodStart: _selectedMonth,
      periodEnd: endMonth,
      reportDate: DateTime.now(),
    );
  }

  Future<void> _downloadPdf() async {
    final pdfBytes = await _generatePdf();
    if (pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  Future<void> _sharePdf() async {
    final pdfBytes = await _generatePdf();
    if (pdfBytes == null) return;
    final month = DateFormat('MMMM-yyyy').format(_selectedMonth);
    await ReportPdfService.sharePdf(pdfBytes, 'CK4_$month.pdf', text: 'Laporan CK-4 Periode $month');
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download PDF'),
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
            onPressed: _sharePdf,
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
    );
  }

  Widget _buildHeroBanner({required String title, required String value, required String subtitle, required Color gradientStart, required Color gradientEnd, required Color textColor, required Color valueColor, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gradientStart, gradientEnd]), borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 16),
        Text(value, style: TextStyle(color: valueColor, fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1)),
        const SizedBox(height: 12),
        Text(subtitle, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildSubSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSmallHeroCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white70 : color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCigaretteStockCard(bool isDark, Map<String, dynamic> c) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final stock = (c['stock'] as num?)?.toInt() ?? 0;
    final sticksPerPack = (c['sticks_per_pack'] as num?)?.toInt() ?? 12;
    final sticks = stock * sticksPerPack;
    final brandName = c['brands']?['name'] ?? 'Merek';
    final variantText = c['variant'] != null && c['variant'].toString().isNotEmpty ? ' • ${c['variant']}' : '';
    
    Color statusColor;
    String statusLabel;
    if (stock == 0) {
      statusColor = AppTheme.error;
      statusLabel = 'Habis';
    } else if (stock <= 100) {
      statusColor = Colors.orange;
      statusLabel = 'Menipis';
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Aman';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c['product_name'] ?? '-',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppTheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$brandName • ${c['cigarette_type'] ?? '-'}$variantText • $sticksPerPack btg/pak',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat('#,###').format(stock),
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'pak',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppTheme.outline,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(${NumberFormat('#,###').format(sticks)} btg)',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppTheme.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStokContent(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(
        children: [
          Expanded(
            child: _buildSmallHeroCard(
              title: 'TOTAL STOK (PAK)',
              value: NumberFormat('#,###').format(_totalStockPacks),
              color: AppTheme.primary,
              bgColor: AppTheme.primary.withValues(alpha: 0.08),
              icon: Icons.inventory_2_outlined,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallHeroCard(
              title: 'TOTAL STOK (BTG)',
              value: NumberFormat('#,###').format(_totalStockSticks),
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFF10B981).withValues(alpha: 0.08),
              icon: Icons.splitscreen_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _buildSubSectionHeader('Stok Produk Saat Ini', isDark),
      const SizedBox(height: 12),
      if (_cigarettes.isEmpty)
        Center(child: Text('Belum ada data persediaan produk', style: TextStyle(color: AppTheme.outline)))
      else
        ..._cigarettes.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCigaretteStockCard(isDark, c),
        )),
      const SizedBox(height: 24),
      _buildSectionHeader('Daftar Produksi', isDark),
      const SizedBox(height: 16),
      if (_productions.isEmpty)
        Center(child: Text('Belum ada data produksi bulan ini', style: TextStyle(color: AppTheme.outline)))
      else
        ..._productions.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildProdCard(isDark, p),
        )),
      _buildActionButtons(isDark),
    ]);
  }

  Widget _buildProdCard(bool isDark, Map<String, dynamic> p) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final hje = (p['hje'] as num?) ?? 0;
    final jumlahIsi = (p['jumlah_isi'] as int?) ?? 0;
    final totalNilai = hje * jumlahIsi;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
            title: 'Produksi ${p['merek']} (${p['jenis']})',
            subtitle: 'No. ${p['doc_number']}',
            amount: '${NumberFormat('#,###').format(jumlahIsi)} ${p['satuan']}',
            status: 'Produksi',
            date: p['doc_date'] ?? '-',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF10B981),
            details: {
              'No. Dokumen': p['doc_number'] ?? '-',
              'Tanggal': p['doc_date'] ?? '-',
              'Merek': p['merek'] ?? '-',
              'Jenis': p['jenis'] ?? '-',
              'HJE': 'Rp ${NumberFormat('#,###').format(hje)}',
              'Bahan Kemasan': p['bahan_kemasan'] ?? '-',
              'Isi': '${p['isi']} ${p['satuan']}',
              'Jumlah Kemasan': NumberFormat('#,###').format(p['jumlah_kemasan']),
              'Jumlah Isi': '${NumberFormat('#,###').format(jumlahIsi)} ${p['satuan']}',
              'Total Nilai Produksi': 'Rp ${NumberFormat('#,###').format(totalNilai)}',
            },
          )));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['merek'] ?? '-', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${p['jenis']} • Isi: ${p['isi']} ${p['satuan']} • ${p['doc_date'] ?? ''}', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(NumberFormat('#,###').format(p['jumlah_kemasan']), style: TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w800)),
              Text('kemasan', style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 11)),
            ]),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildCukaiContent(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildHeroBanner(
        title: 'SISA PITA CUKAI', value: NumberFormat('#,###').format(_sisaCukai),
        subtitle: 'Total sisa alokasi aktif',
        gradientStart: AppTheme.tertiaryFixed, gradientEnd: AppTheme.tertiaryFixedDim,
        textColor: AppTheme.tertiary, valueColor: AppTheme.onTertiaryFixed, icon: Icons.confirmation_number_outlined,
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('Riwayat Penggunaan', isDark),
      const SizedBox(height: 16),
      if (_cukaiUsages.isEmpty)
        Center(child: Text('Belum ada data pemakaian cukai', style: TextStyle(color: AppTheme.outline)))
      else
        ..._cukaiUsages.map((u) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCukaiCard(isDark, u),
        )),
      _buildActionButtons(isDark),
    ]);
  }

  Widget _buildCukaiCard(bool isDark, Map<String, dynamic> u) {
    final used = u['used_amount'] as int;
    final added = u['added_amount'] as int;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
            title: 'Pemakaian Cukai',
            subtitle: u['notes'] ?? 'Pencatatan pemakaian pita cukai',
            amount: used > 0 ? '-$used lembar' : '+$added lembar',
            status: 'Cukai',
            date: u['usage_date'] ?? '-',
            icon: Icons.confirmation_number_outlined,
            color: const Color(0xFF6366F1),
            details: {
              'Tanggal': u['usage_date'] ?? '-',
              'Pemakaian': '$used lembar',
              'Tambahan': '$added lembar',
              'Catatan': u['notes'] ?? '-',
            },
          )));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u['usage_date'] ?? '-', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              if (u['notes'] != null) ...[
                const SizedBox(height: 4),
                Text(u['notes'], style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 12)),
              ],
            ])),
            Row(children: [
              if (used > 0) Text('-$used', style: TextStyle(color: AppTheme.error, fontSize: 18, fontWeight: FontWeight.w800)),
              if (used > 0 && added > 0) const SizedBox(width: 12),
              if (added > 0) Text('+$added', style: TextStyle(color: const Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildKeluarContent(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildHeroBanner(
        title: 'TOTAL PRODUK KELUAR', value: NumberFormat('#,###').format(_totalKeluar),
        subtitle: 'Periode ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
        gradientStart: AppTheme.secondaryFixed, gradientEnd: AppTheme.secondaryContainer,
        textColor: AppTheme.secondary, valueColor: AppTheme.onSecondaryFixed, icon: Icons.local_shipping_outlined,
      ),
      const SizedBox(height: 24),
      _buildSectionHeader('Riwayat Transaksi', isDark),
      const SizedBox(height: 16),
      if (_outgoingGoods.isEmpty)
        Center(child: Text('Belum ada data barang keluar', style: TextStyle(color: AppTheme.outline)))
      else
        ..._outgoingGoods.map((o) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOutgoingCard(isDark, o),
        )),
      _buildActionButtons(isDark),
    ]);
  }

  Widget _buildOutgoingCard(bool isDark, Map<String, dynamic> o) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isKredit = o['payment_method'] == 'kredit';
    final totalValue = (o['total_value'] as num?) ?? 0;

    final cig = o['cigarettes'] as Map<String, dynamic>?;
    final productName = cig?['product_name'] ?? '-';
    final brandName = cig?['brands']?['name'] ?? '-';
    final cigaretteType = cig?['cigarette_type'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
            title: 'Keluar → ${o['customer_name']}',
            subtitle: '${o['transaction_date']}',
            amount: '${NumberFormat('#,###').format(o['volume'])} btg',
            status: 'Keluar',
            date: o['transaction_date'] ?? '-',
            icon: Icons.shopping_cart_checkout_outlined,
            color: AppTheme.error,
            details: {
              'Tanggal': o['transaction_date'] ?? '-',
              'Pelanggan': o['customer_name'] ?? '-',
              'Produk / Merek': '$productName ($brandName)',
              'Jenis Rokok': cigaretteType,
              'Volume': '${NumberFormat('#,###').format(o['volume'])} btg',
              'Total Nilai': 'Rp ${NumberFormat('#,###').format(totalValue)}',
              'Pembayaran': isKredit ? 'KREDIT' : 'TUNAI',
              if (cig?['hje'] != null) 'HJE': 'Rp ${NumberFormat('#,###').format(cig!['hje'])}',
              if (cig?['excise_rate'] != null) 'Tarif Cukai': 'Rp ${NumberFormat('#,###').format(cig!['excise_rate'])}/btg',
            },
          )));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(
                child: Text(
                  '${o['customer_name'] ?? '-'} • $productName ($brandName)',
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isKredit ? AppTheme.secondaryContainer : AppTheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Text(isKredit ? 'KREDIT' : 'TUNAI', style: TextStyle(color: isKredit ? AppTheme.onSecondaryContainer : AppTheme.onTertiaryContainer, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${o['transaction_date']}', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(width: 16),
              Text('${NumberFormat('#,###').format(o['volume'])} btg', style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('Rp ${NumberFormat('#,###').format(totalValue)}', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }
}
