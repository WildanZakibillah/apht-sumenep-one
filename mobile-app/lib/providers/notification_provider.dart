import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages notification state: fetching, realtime updates, unread count.
class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _userId;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length;

  /// Initialize with user ID and start listening
  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    fetchNotifications();
    _subscribeRealtime();
  }

  /// Clear state on logout
  void clear() {
    _userId = null;
    _notifications = [];
    _channel?.unsubscribe();
    _channel = null;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('NotificationProvider: fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    if (_userId == null) return;

    _channel = Supabase.instance.client
        .channel('notifications_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            _notifications.insert(0, Map<String, dynamic>.from(payload.newRecord));
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            final idx = _notifications.indexWhere((n) => n['id'] == updated['id']);
            if (idx != -1) {
              _notifications[idx] = updated;
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            final oldId = payload.oldRecord['id'];
            _notifications.removeWhere((n) => n['id'] == oldId);
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _notifications[idx] = {..._notifications[idx], 'is_read': true};
      notifyListeners();
    }

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    // Optimistic update
    _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList();
    notifyListeners();

    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _userId!)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n['id'] == id);
    notifyListeners();

    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', id);
  }

  Future<void> deleteMultiple(List<String> ids) async {
    _notifications.removeWhere((n) => ids.contains(n['id']));
    notifyListeners();

    await Supabase.instance.client
        .from('notifications')
        .delete()
        .inFilter('id', ids);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
