import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../activity_detail_screen.dart';

class _HistoryItem {
  final String title;
  final String date;
  final String value;
  final Color valueColor;
  final String statusText;
  final IconData icon;
  final Color iconColor;
  final DateTime sortDate;
  final Map<String, String> details;

  _HistoryItem({
    required this.title,
    required this.date,
    required this.value,
    required this.valueColor,
    required this.statusText,
    required this.icon,
    required this.iconColor,
    required this.sortDate,
    required this.details,
  });
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late Future<List<_HistoryItem>> _historyFuture;
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchAllHistory();
  }

  void _refresh() {
    setState(() {
      _historyFuture = _fetchAllHistory();
    });
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _historyFuture = _fetchAllHistory();
      });
    }
  }

  Future<List<_HistoryItem>> _fetchAllHistory() async {
    final auth = context.read<AuthProvider>();
    final factoryId = auth.profile?.factoryId;
    if (factoryId == null) return [];

    final client = Supabase.instance.client;
    final items = <_HistoryItem>[];

    final startDate = _selectedMonth.toIso8601String().split('T').first;
    final endMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    final endDate = endMonth.toIso8601String().split('T').first;

    // Fetch productions
    try {
      final productions = await client
          .from('productions')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', startDate)
          .lt('created_at', endDate)
          .order('created_at', ascending: false)
          .limit(100);

      for (final p in productions) {
        final hje = (p['hje'] as num?) ?? 0;
        final jumlahIsi = (p['jumlah_isi'] as int?) ?? 0;
        final totalNilai = hje * jumlahIsi;
        items.add(_HistoryItem(
          title: 'Produksi ${p['merek']} (${p['jenis']})',
          date: _formatDate(p['created_at']),
          value: '+${NumberFormat('#,###').format(jumlahIsi)} ${p['satuan']}',
          valueColor: const Color(0xFF10B981),
          statusText: 'Produksi',
          icon: Icons.inventory_2_outlined,
          iconColor: const Color(0xFF10B981),
          sortDate: DateTime.parse(p['created_at']),
          details: {
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
        ));
      }
    } catch (_) {}

    // Fetch cukai usage
    try {
      final usages = await client
          .from('cukai_usage_log')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', startDate)
          .lt('created_at', endDate)
          .order('created_at', ascending: false)
          .limit(100);

      for (final u in usages) {
        final used = u['used_amount'] as int;
        final added = u['added_amount'] as int;
        final label = used > 0 ? '-$used lembar' : '+$added lembar';
        items.add(_HistoryItem(
          title: 'Pemakaian Cukai${u['notes'] != null ? ' • ${u['notes']}' : ''}',
          date: _formatDate(u['created_at']),
          value: label,
          valueColor: used > 0 ? AppTheme.error : const Color(0xFF10B981),
          statusText: 'Cukai',
          icon: Icons.confirmation_number_outlined,
          iconColor: const Color(0xFF6366F1),
          sortDate: DateTime.parse(u['created_at']),
          details: {
            'Tanggal': u['usage_date'] ?? '-',
            'Pemakaian': '$used lembar',
            'Tambahan': '$added lembar',
            'Catatan': u['notes'] ?? '-',
          },
        ));
      }
    } catch (_) {}

    // Fetch outgoing goods
    try {
      final outgoing = await client
          .from('outgoing_goods')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', startDate)
          .lt('created_at', endDate)
          .order('created_at', ascending: false)
          .limit(100);

      for (final o in outgoing) {
        final totalValue = (o['total_value'] as num?) ?? 0;
        items.add(_HistoryItem(
          title: 'Keluar → ${o['customer_name']}',
          date: _formatDate(o['created_at']),
          value: '${NumberFormat('#,###').format(o['volume'])} btg',
          valueColor: AppTheme.error,
          statusText: 'Keluar',
          icon: Icons.shopping_cart_checkout_outlined,
          iconColor: AppTheme.error,
          sortDate: DateTime.parse(o['created_at']),
          details: {
            'Tanggal': o['transaction_date'] ?? '-',
            'Pelanggan': o['customer_name'] ?? '-',
            'Volume': '${NumberFormat('#,###').format(o['volume'])} btg',
            'Total Nilai': 'Rp ${NumberFormat('#,###').format(totalValue)}',
            'Pembayaran': (o['payment_method'] as String?)?.toUpperCase() ?? '-',
          },
        ));
      }
    } catch (_) {}

    // Fetch cukai requests
    try {
      final requests = await client
          .from('cukai_requests')
          .select()
          .eq('factory_id', factoryId)
          .gte('created_at', startDate)
          .lt('created_at', endDate)
          .order('created_at', ascending: false)
          .limit(100);

      for (final r in requests) {
        final status = r['status'] as String;
        final statusLabel = status == 'approved' ? 'Disetujui' : status == 'rejected' ? 'Ditolak' : 'Pending';
        final tarif = (r['tarif_cukai'] as num?) ?? 0;
        final lembar = (r['jumlah_lembar'] as int?) ?? 0;
        items.add(_HistoryItem(
          title: 'Pengajuan ${r['jenis_pengajuan']} • ${r['jenis_hasil_tembakau']}',
          date: _formatDate(r['created_at']),
          value: statusLabel,
          valueColor: status == 'approved' ? const Color(0xFF10B981) : status == 'rejected' ? AppTheme.error : Colors.amber,
          statusText: 'Pengajuan',
          icon: Icons.assignment_outlined,
          iconColor: const Color(0xFF6366F1),
          sortDate: DateTime.parse(r['created_at']),
          details: {
            'No. Dokumen': r['doc_number'] ?? '-',
            'Tanggal': r['request_date'] ?? '-',
            'Jenis Pengajuan': r['jenis_pengajuan'] ?? '-',
            'Jenis Tembakau': r['jenis_hasil_tembakau'] ?? '-',
            'Jumlah Lembar': NumberFormat('#,###').format(lembar),
            'Tarif Cukai': 'Rp ${NumberFormat('#,###').format(tarif)}',
            'Total Nilai Cukai': 'Rp ${NumberFormat('#,###').format(tarif * lembar)}',
            'Status': statusLabel,
          },
        ));
      }
    } catch (_) {}

    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items;
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(backgroundColor),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(isDark),
                const SizedBox(height: 12),
                _buildMonthLabel(isDark),
                const SizedBox(height: 12),
                FutureBuilder<List<_HistoryItem>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('Gagal memuat data: ${snapshot.error}', style: TextStyle(color: AppTheme.error))));
                    }

                    var items = snapshot.data ?? [];
                    if (_searchQuery.isNotEmpty) {
                      items = items.where((i) => i.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    }

                    if (items.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Belum ada riwayat aktivitas.')));
                    }

                    return Column(
                      children: items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActivityCard(isDark: isDark, item: item),
                      )).toList(),
                    );
                  },
                ),
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
      title: Text('Riwayat', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1)),
    );
  }

  Widget _buildMonthLabel(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
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
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Cari Riwayat...',
                hintStyle: TextStyle(color: AppTheme.outline),
                prefixIcon: Icon(Icons.search, color: AppTheme.outline),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: AppTheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: IconButton(
            onPressed: _pickMonth,
            icon: const Icon(Icons.filter_list_rounded),
            color: AppTheme.onPrimaryContainer,
            tooltip: 'Filter Bulan',
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard({required bool isDark, required _HistoryItem item}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
            title: item.title,
            subtitle: '${item.statusText} • ${item.date}',
            amount: item.value,
            status: item.statusText,
            date: item.date,
            icon: item.icon,
            color: item.iconColor,
            details: item.details,
          )));
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: item.iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(item.title, style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(item.value, style: TextStyle(color: item.valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  const SizedBox(height: 4),
                  Text(item.date, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(8)),
                child: Text(item.statusText, style: TextStyle(color: item.iconColor, fontWeight: FontWeight.w700, fontSize: 10)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
