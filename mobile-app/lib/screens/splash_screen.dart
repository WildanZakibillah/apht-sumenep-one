import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahan untuk mengatur Status Bar
import 'package:provider/provider.dart';
import '../core/supabase_client.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // Sedikit diperlambat agar lebih smooth
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500)); // Waktu tampil splash screen
    if (!mounted) return;
    await _navigateNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final isLoggedIn = SupabaseConfig.isAuthenticated;

    if (isLoggedIn) {
      try {
        final auth = context.read<AuthProvider>();
        // Timeout 5 detik agar tidak stuck selamanya
        await auth.ensureProfileLoaded().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
      } catch (_) {
        // Jika gagal load profile, tetap lanjut navigasi
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            isLoggedIn ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AnnotatedRegion digunakan untuk mengatur tampilan jam & batre di status bar
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Membuat background status bar transparan
        statusBarIconBrightness: Brightness.dark, // Ikon batre dan jam berwarna gelap
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // Menggunakan gradient agar tampilan tidak terlalu flat/polos
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF0F4FA), // Biru sangat muda di bagian bawah
              ],
            ),
          ),
          child: Stack(
            children: [
              // Konten Utama di Tengah
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Container Logo
                        Container(
                          width: 120, // Sedikit diperbesar agar lebih proporsional
                          height: 120,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              // Shadow utama (lembut)
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                blurRadius: 40,
                                spreadRadius: 5,
                                offset: const Offset(0, 15),
                              ),
                              // Shadow kedua (tegas)
                              BoxShadow(
                                color: const Color(0xFF1E3A8A).withOpacity(0.04),
                                blurRadius: 10,
                                spreadRadius: -5,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logoapht.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Teks Judul
                        const Text(
                          'APHT ONE',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 28, // Diperbesar sedikit
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Teks Sub-judul
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'APHT Sumenep',
                            style: TextStyle(
                              color: Color(0xFF475569), // Warna slate (abu kebiruan)
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Loading Indicator opsional di bagian paling bawah layar
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF1E3A8A).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}