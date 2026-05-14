import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'core/supabase_client.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseConfig.init();

  // Load saved theme before app starts
  await AppTheme.loadTheme();

  runApp(const AphtSumenepOneApp());
}

class AphtSumenepOneApp extends StatefulWidget {
  const AphtSumenepOneApp({super.key});

  @override
  State<AphtSumenepOneApp> createState() => _AphtSumenepOneAppState();
}

class _AphtSumenepOneAppState extends State<AphtSumenepOneApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthProviderScope(
      authProvider: _authProvider,
      child: ValueListenableBuilder<bool>(
        valueListenable: AppTheme.isDarkMode,
        builder: (context, isDark, _) {
          return MaterialApp(
            title: 'APHT Sumenep One',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// InheritedWidget to provide [AuthProvider] down the widget tree
/// without adding a dependency on the `provider` package.
class AuthProviderScope extends InheritedNotifier<AuthProvider> {
  final AuthProvider authProvider;

  AuthProviderScope({
    super.key,
    required this.authProvider,
    required super.child,
  }) : super(notifier: authProvider);

  static AuthProvider of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AuthProviderScope>();
    assert(scope != null, 'No AuthProviderScope found in context');
    return scope!.authProvider;
  }
}
