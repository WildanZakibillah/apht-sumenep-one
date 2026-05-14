import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/constants.dart';
import '../models/profile.dart';

/// Service handling all authentication operations via Supabase Auth.
class AuthService {
  AuthService._();

  static final _client = SupabaseConfig.client;

  /// Sign in with email and password.
  /// Returns the authenticated [User] on success.
  /// Throws an [AuthException] on failure.
  static Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user!;
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get the current auth session, or null if not authenticated.
  static Session? get currentSession => _client.auth.currentSession;

  /// Get the current authenticated user, or null.
  static User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently authenticated.
  static bool get isAuthenticated => currentSession != null;

  /// Fetch the [Profile] for the currently authenticated user.
  /// Returns null if no user is signed in or profile not found.
  static Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from(AppConstants.tableProfiles)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  /// Listen to auth state changes (login, logout, token refresh).
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;
}
