import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/wib_helper.dart';
import 'activity_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Map<String, dynamic>> notifications) {
    setState(() {
      if (_selectedIds.length == notifications.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(notifications.map((n) => n['id'] as String));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: Text('Hapus ${_selectedIds.length} notifikasi yang dipilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Hapus', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<NotificationProvider>().deleteMultiple(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectMode = false;
      });
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'check_circle_outline_rounded': return Icons.check_circle_outline_rounded;
      case 'warning_amber_rounded': return Icons.warning_amber_rounded;
      case 'description_outlined': return Icons.description_outlined;
      case 'local_shipping_outlined': return Icons.local_shipping_outlined;
      case 'inventory_2_outlined': return Icons.inventory_2_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'success': return const Color(0xFF10B981);
      case 'warning': return const Color(0xFFF59E0B);
      case 'error': return AppTheme.error;
      default: return AppTheme.primary;
    }
  }

  Future<void> _openCukaiRequestDetail(BuildContext ctx, String requestId, Map<String, dynamic> n, String timeStr, IconData icon, Color color) async {
    final nav = Navigator.of(ctx);
    final auth = ctx.read<AuthProvider>();
    try {
      final res = await Supabase.instance.client
          .from('cukai_requests')
          .select('*, factories(name, code, address)')
          .eq('id', requestId)
          .maybeSingle();

      if (res == null || !mounted) return;

      final factory = res['factories'] as Map<String, dynamic>?;
      final tarif = (res['tarif_cukai'] as num?) ?? 0;
      final hje = (res['hje'] as num?) ?? 0;
      final lembar = (res['jumlah_lembar'] as int?) ?? 0;
      final statusRaw = res['status'] as String? ?? 'pending';
      final statusLabel = statusRaw == 'approved' ? 'Disetujui' : statusRaw == 'rejected' ? 'Ditolak' : 'Pending';

      nav.push(MaterialPageRoute(builder: (_) => ActivityDetailScreen(
        title: n['title'] ?? 'Pengajuan Cukai',
        subtitle: n['message'] ?? '',
        amount: statusLabel,
        status: 'Pengajuan',
        date: res['request_date'] ?? timeStr,
        icon: icon,
        color: color,
        details: {
          'No. Dokumen': res['doc_number'] ?? '-',
          'Tanggal': res['request_date'] ?? '-',
          'Jenis Pengajuan': res['jenis_pengajuan'] ?? '-',
          'Lokasi Penyediaan': res['lokasi_penyediaan'] ?? '-',
          'Jenis Tembakau': res['jenis_hasil_tembakau'] ?? '-',
          'Kode Personalisasi': res['kode_personalisasi'] ?? '-',
          'Seri': res['seri'] ?? '-',
          'Warna': res['warna'] ?? '-',
          'Tarif Cukai': '${tarif.toInt()}',
          'HJE': '${hje.toInt()}',
          'Isi/Bks': '${res['isi_per_bks'] ?? 0}',
          'Jumlah Lembar': '$lembar',
          'Total Nilai Cukai': 'Rp ${NumberFormat('#,###').format(tarif * lembar)}',
          'Status': statusLabel,
          'Nama Pabrik': factory?['name'] ?? '-',
          'Alamat Pabrik': factory?['address'] ?? '-',
          'NPPBKC': factory?['code'] ?? '-',
          'Nama Pengusaha': auth.profile?.fullName ?? '-',
        },
      )));
    } catch (e) {
      // Fallback to generic detail
      if (!mounted) return;
      final metadata = n['metadata'] as Map<String, dynamic>?;
      nav.push(MaterialPageRoute(builder: (_) => ActivityDetailScreen(
        title: n['title'] ?? 'Notifikasi',
        subtitle: n['message'] ?? '',
        amount: '',
        status: (n['type'] as String?)?.toUpperCase() ?? 'INFO',
        date: timeStr,
        icon: icon,
        color: color,
        details: {
          'Pesan': n['message'] ?? '-',
          'Waktu': timeStr,
          if (metadata != null) ...metadata.map((k, v) => MapEntry(k, v.toString())),
        },
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final notifications = notifProvider.notifications;
        final isLoading = notifProvider.isLoading;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor, elevation: 0, scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () {
                if (_isSelectMode) {
                  _toggleSelectMode();
                } else {
                  Navigator.pop(context);
                }
              },
              icon: Icon(
                _isSelectMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppTheme.onSurface, size: 20,
              ),
            ),
            title: Text(
              _isSelectMode ? '${_selectedIds.length} dipilih' : 'Notifikasi',
              style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: _isSelectMode
                ? [
                    IconButton(
                      onPressed: () => _selectAll(notifications),
                      icon: Icon(
                        _selectedIds.length == notifications.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                        color: AppTheme.primary, size: 22,
                      ),
                      tooltip: 'Pilih Semua',
                    ),
                    IconButton(
                      onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
                      icon: Icon(Icons.delete_outline_rounded, color: _selectedIds.isNotEmpty ? AppTheme.error : AppTheme.outline, size: 22),
                      tooltip: 'Hapus',
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                    IconButton(
                      onPressed: () => notifProvider.markAllAsRead(),
                      icon: Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22),
                      tooltip: 'Tandai semua dibaca',
                    ),
                    IconButton(
                      onPressed: notifications.isNotEmpty ? _toggleSelectMode : null,
                      icon: Icon(Icons.checklist_rounded, color: notifications.isNotEmpty ? AppTheme.onSurfaceVariant : AppTheme.outline, size: 22),
                      tooltip: 'Pilih',
                    ),
                    const SizedBox(width: 8),
                  ],
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1)),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.outline),
                      const SizedBox(height: 16),
                      Text('Belum ada notifikasi', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () async => notifProvider.fetchNotifications(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return _buildNotificationItem(isDark, n, notifProvider);
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildNotificationItem(bool isDark, Map<String, dynamic> n, NotificationProvider notifProvider) {
    final isUnread = !(n['is_read'] as bool? ?? false);
    final icon = _getIcon(n['icon'] as String?);
    final color = _getColor(n['type'] as String?);
    final createdAt = WIB.parse(n['created_at']);
    final timeStr = DateFormat('dd MMM, HH:mm').format(createdAt);
    final metadata = n['metadata'] as Map<String, dynamic>?;
    final id = n['id'] as String;
    final isSelected = _selectedIds.contains(id);

    final bgColor = _isSelectMode && isSelected
        ? AppTheme.primary.withValues(alpha: 0.1)
        : isDark
            ? (isUnread ? const Color(0xFF1E293B) : Colors.transparent)
            : (isUnread ? AppTheme.primary.withValues(alpha: 0.04) : Colors.transparent);

    return Dismissible(
      key: Key(id),
      direction: _isSelectMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error.withValues(alpha: 0.1),
        child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Notifikasi'),
            content: const Text('Hapus notifikasi ini?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Hapus', style: TextStyle(color: AppTheme.error))),
            ],
          ),
        );
      },
      onDismissed: (_) => notifProvider.deleteNotification(id),
      child: Material(
        color: bgColor,
        child: InkWell(
          onTap: () async {
            if (_isSelectMode) {
              _toggleSelection(id);
              return;
            }
            if (isUnread) notifProvider.markAsRead(id);

            // Check if this is a cukai request notification (has request_id in metadata)
            final requestId = metadata?['request_id']?.toString();
            if (requestId != null && requestId != 'null') {
              await _openCukaiRequestDetail(context, requestId, n, timeStr, icon, color);
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailScreen(
                title: n['title'] ?? 'Notifikasi',
                subtitle: n['message'] ?? '',
                amount: '',
                status: (n['type'] as String?)?.toUpperCase() ?? 'INFO',
                date: timeStr,
                icon: icon,
                color: color,
                details: {
                  'Pesan': n['message'] ?? '-',
                  'Waktu': timeStr,
                  'Tipe': (n['type'] as String?)?.toUpperCase() ?? 'INFO',
                  if (metadata != null) ...metadata.map((k, v) => MapEntry(k, v.toString())),
                },
              )));
            }
          },
          onLongPress: () {
            if (!_isSelectMode) {
              _toggleSelectMode();
              _toggleSelection(id);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_isSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(id),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 8),
              ],
              Stack(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (isUnread)
                  Positioned(top: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: AppTheme.error, shape: BoxShape.circle, border: Border.all(color: bgColor, width: 2)))),
              ]),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(n['title'] ?? '', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 15, fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600))),
                  const SizedBox(width: 8),
                  Text(timeStr, style: TextStyle(color: isDark ? Colors.white54 : AppTheme.outline, fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 6),
                Text(n['message'] ?? '', style: TextStyle(color: isDark ? (isUnread ? Colors.white70 : Colors.white54) : (isUnread ? AppTheme.onSurfaceVariant : AppTheme.outline), fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              if (!_isSelectMode) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
