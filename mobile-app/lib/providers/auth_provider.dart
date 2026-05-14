import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

/// Centralized authentication state management.
/// Listens to Supabase auth changes and exposes the current user profile.
class AuthProvider extends ChangeNotifier {
  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;

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
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Failed to load profile: $e');
    } finally {
      _profileCompleter?.complete();
    }
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
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
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
    super.dispose();
  }
}
