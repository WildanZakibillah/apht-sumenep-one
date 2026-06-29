import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _userId;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length;

  void init(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribe();
    fetchNotifications();
  }

  void clear() {
    _unsubscribe();
    _userId = null;
    _notifications = [];
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
          .order('created_at', ascending: false);

      _notifications = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('NotificationProvider: fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    if (_userId == null) return;
    _unsubscribe();

    _channel = Supabase.instance.client
        .channel('public:notifications:user_$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              _notifications.insert(0, Map<String, dynamic>.from(payload.newRecord));
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final idx = _notifications.indexWhere((n) => n['id'] == payload.newRecord['id']);
              if (idx != -1) {
                _notifications[idx] = Map<String, dynamic>.from(payload.newRecord);
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              _notifications.removeWhere((n) => n['id'] == payload.oldRecord['id']);
            }
            notifyListeners();
          },
        );
    _channel?.subscribe();
  }

  void _unsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1) {
        _notifications[idx]['is_read'] = true;
        notifyListeners();
      }
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('NotificationProvider: markAsRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      _notifications.removeWhere((n) => n['id'] == id);
      notifyListeners();
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('NotificationProvider: deleteNotification error: $e');
    }
  }

  Future<void> deleteMultiple(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      _notifications.removeWhere((n) => ids.contains(n['id']));
      notifyListeners();
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .inFilter('id', ids);
    } catch (e) {
      debugPrint('NotificationProvider: deleteMultiple error: $e');
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
