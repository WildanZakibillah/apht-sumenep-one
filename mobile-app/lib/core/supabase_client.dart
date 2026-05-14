import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton accessor for the Supabase client instance.
/// Must call [initSupabase] before accessing [supabase].
class SupabaseConfig {
  SupabaseConfig._();

  /// Initialize Supabase with credentials from .env
  static Future<void> init() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  /// The global Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the current auth session.
  static Session? get currentSession => client.auth.currentSession;

  /// Shortcut to the current authenticated user.
  static User? get currentUser => client.auth.currentUser;

  /// Whether the user is currently authenticated.
  static bool get isAuthenticated => currentSession != null;
}
