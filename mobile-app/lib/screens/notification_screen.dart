import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectMode = false;

  @override
  void initState() {
    super.initState();
    // Refresh notifications on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectMode = false;
      }
    });
  }

  void _selectAll(List<Map<String, dynamic>> notifications) {
    setState(() {
      if (_selectedIds.length == notifications.length) {
        _selectedIds.clear();
        _isSelectMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(notifications.map((n) => n['id'] as String));
        _isSelectMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedIds.length} notifikasi terpilih?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && mounted) {
      final notifProvider = context.read<NotificationProvider>();
      await notifProvider.deleteMultiple(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectMode = false;
      });
    }
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'check_circle': return Icons.check_circle_outline_rounded;
      case 'cancel': return Icons.cancel_outlined;
      case 'warning': return Icons.warning_amber_rounded;
      case 'error': return Icons.error_outline_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'success': return const Color(0xFF10B981);
      case 'error': return AppTheme.error;
      case 'warning': return const Color(0xFFF59E0B);
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppTheme.onSurface, size: 20),
        ),
        title: Text(
          _isSelectMode ? '${_selectedIds.length} terpilih' : 'Notifikasi',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final notifications = notifProvider.notifications;
              return Row(
                children: [
                  if (_isSelectMode)
                    IconButton(
                      onPressed: () => _selectAll(notifications),
                      icon: Icon(
                        _selectedIds.length == notifications.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                  if (_isSelectMode && _selectedIds.isNotEmpty)
                    IconButton(
                      onPressed: _deleteSelected,
                      icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 22),
                    ),
                  IconButton(
                    onPressed: notifications.isNotEmpty ? _toggleSelectMode : null,
                    icon: Icon(
                      _isSelectMode ? Icons.close_rounded : Icons.checklist_rounded,
                      color: notifications.isNotEmpty ? (isDark ? Colors.white70 : AppTheme.onSurfaceVariant) : AppTheme.outline,
                      size: 22,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          final notifications = notifProvider.notifications;

          if (notifProvider.isLoading && notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi',
                    style: TextStyle(color: isDark ? Colors.white38 : AppTheme.outline, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => notifProvider.fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildNotificationItem(isDark, n, notifProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(bool isDark, Map<String, dynamic> n, NotificationProvider notifProvider) {
    final id = n['id'] as String;
    final title = n['title'] as String? ?? 'Notifikasi';
    final message = n['message'] as String? ?? '';
    final type = n['type'] as String? ?? 'info';
    final iconName = n['icon'] as String?;
    final isRead = n['is_read'] as bool? ?? false;
    final createdAt = n['created_at'] != null ? DateTime.parse(n['created_at'] as String).toLocal() : DateTime.now();

    final itemBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderCol = isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.outlineVariant.withValues(alpha: 0.5);

    final isSelected = _selectedIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppTheme.primary : borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            offset: const Offset(0, 4),
            blurRadius: 10,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () {
            if (!_isSelectMode) {
              setState(() {
                _isSelectMode = true;
                _selectedIds.add(id);
              });
            }
          },
          onTap: () {
            if (_isSelectMode) {
              _toggleSelect(id);
            } else {
              if (!isRead) {
                notifProvider.markAsRead(id);
              }
              // Display detail modal dialog
              _showDetailDialog(title, message, createdAt);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSelectMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelect(id),
                    activeColor: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getColor(type).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIcon(iconName), color: _getColor(type), size: 20),
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
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppTheme.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                        style: TextStyle(color: isDark ? Colors.white30 : AppTheme.outline, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(String title, String message, DateTime date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(date),
              style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
