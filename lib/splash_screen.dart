import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class _AuthColors {
  static const surface = Colors.white;
  static const grey = Color(0xFF8E8E8E);
  static const divider = Color(0xFFDBDBDB);

  static const gradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFFFEDA77),
      Color(0xFFF58529),
      Color(0xFFDD2A7B),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _progressController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  static const _splashDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();

    // Logo fade + subtle scale-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Bottom progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    );

    _fadeController.forward();
    _progressController.forward();

    Timer(_splashDuration, () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AuthColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ─────────── Center: ZING logo + tagline ───────────
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              _AuthColors.gradient.createShader(bounds),
                          child: Text(
                            "ZING",
                            style: GoogleFonts.pacifico(
                              color: Colors.white,
                              fontSize: 76,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Next generation e-commerce",
                          style: TextStyle(
                            color: _AuthColors.grey,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─────────── Bottom: gradient progress + Meta-style sign-off ───
            Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                children: [
                  // Thin gradient progress bar
                  SizedBox(
                    width: 140,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          Container(color: _AuthColors.divider),
                          AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _progressController.value,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: _AuthColors.gradient,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "from",
                    style: TextStyle(
                      color: _AuthColors.grey.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _AuthColors.gradient.createShader(bounds),
                    child: const Text(
                      "ZING Ecosystem",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}