import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'activity_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.profile?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.profile?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);

    _loadNotifications();
  }

  Future<void> _markRead(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20)),
        title: Text('Notifikasi', style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _markAllRead, icon: Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22), tooltip: 'Tandai semua dibaca'),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppTheme.outlineVariant.withValues(alpha: 0.3), height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.outline),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: () async => _loadNotifications(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return _buildNotificationItem(isDark, n);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(bool isDark, Map<String, dynamic> n) {
    final isUnread = !(n['is_read'] as bool? ?? false);
    final icon = _getIcon(n['icon'] as String?);
    final color = _getColor(n['type'] as String?);
    final createdAt = DateTime.parse(n['created_at']);
    final timeStr = DateFormat('dd MMM, HH:mm').format(createdAt);
    final metadata = n['metadata'] as Map<String, dynamic>?;

    final bgColor = isDark
        ? (isUnread ? const Color(0xFF1E293B) : Colors.transparent)
        : (isUnread ? AppTheme.primary.withValues(alpha: 0.04) : Colors.transparent);

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: () {
          if (isUnread) _markRead(n['id']);
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
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : AppTheme.outlineVariant, size: 18),
          ]),
        ),
      ),
    );
  }
}
