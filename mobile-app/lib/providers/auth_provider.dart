import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

/// Centralized authentication state management.
/// Listens to Supabase auth changes and exposes the current user profile.
/// Also subscribes to realtime profile updates (e.g. is_active status changes).
class AuthProvider extends ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _profileChannel;

  AuthProvider() {
    _init();
  }

  // ---------- Getters ----------
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _profile != null;
  String? get errorMessage => _errorMessage;
  String get userDisplayName => _profile?.fullName ?? 'User';
  String get userRole => _profile?.role ?? '';
  String get userEmail => _profile?.email ?? '';

  Completer<void>? _profileCompleter;

  // ---------- Initialization ----------
  void _init() {
    _authSubscription = AuthService.onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _unsubscribeProfileRealtime();
        notifyListeners();
      }
    });

    // Load profile if already authenticated
    if (AuthService.isAuthenticated) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    _profileCompleter = Completer<void>();
    try {
      _profile = await AuthService.getCurrentProfile();
      if (_profile != null) {
        _subscribeProfileRealtime();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Failed to load profile: $e');
      rethrow;
    } finally {
      _profileCompleter?.complete();
    }
  }

  /// Subscribe to realtime changes on the current user's profile row.
  void _subscribeProfileRealtime() {
    _unsubscribeProfileRealtime();
    if (_profile == null) return;

    _profileChannel = Supabase.instance.client
        .channel('profile_${_profile!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _profile!.id,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            if (updated.isNotEmpty) {
              _profile = Profile.fromJson(updated);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void _unsubscribeProfileRealtime() {
    _profileChannel?.unsubscribe();
    _profileChannel = null;
  }

  /// Wait until the profile has been loaded (useful on app startup).
  Future<void> ensureProfileLoaded() async {
    if (_profile != null) return;
    if (_profileCompleter != null && !_profileCompleter!.isCompleted) {
      await _profileCompleter!.future;
    }
  }

  // ---------- Actions ----------

  /// Attempt login with email and password.
  /// Returns true on success, false on failure (check [errorMessage]).
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.signIn(email: email, password: password);
      await _loadProfile();
      
      if (_profile == null) {
        throw Exception('Profil tidak ditemukan atau gagal dimuat.');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem: $e';
      await AuthService.signOut(); // Rollback sign in
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signOut();
      _profile = null;
      _unsubscribeProfileRealtime();
    } catch (e) {
      debugPrint('AuthProvider: Logout error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Clear the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unsubscribeProfileRealtime();
    super.dispose();
  }
}
