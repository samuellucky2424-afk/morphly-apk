import 'dart:async';

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../repositories/auth_repository.dart';
import '../theme/morphly_tokens.dart';
import '../widgets/morphly_components.dart';
import 'camera_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _bootTimer = Timer(
      const Duration(seconds: 5),
      () => unawaited(_routeAfterBoot()),
    );
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _routeAfterBoot() async {
    if (!mounted) return;

    final user = const AuthRepository().currentUser;
    final destination = AppConfig.hasSupabase && user != null
        ? const CameraScreen()
        : const LoginScreen();
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.86,
                          colors: [
                            MorphlyColors.secondary.withValues(alpha: 0.20),
                            MorphlyColors.primary.withValues(alpha: 0.18),
                            MorphlyColors.card,
                          ],
                        ),
                        borderRadius:
                            const BorderRadius.all(MorphlyRadius.xLarge),
                        border: Border.all(
                          color: MorphlyColors.primary.withValues(alpha: 0.46),
                        ),
                        boxShadow: [
                          ...MorphlyShadows.purpleGlow(0.46),
                          ...MorphlyShadows.greenGlow(0.22),
                        ],
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: MorphlyColors.primary,
                            size: 52,
                          ),
                          Positioned(
                            right: 28,
                            bottom: 30,
                            child: Icon(
                              Icons.circle,
                              color: MorphlyColors.secondary,
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Morphly',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: MorphlyColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Live Camera',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MorphlyColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 36),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MorphlyColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
