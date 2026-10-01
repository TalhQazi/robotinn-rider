import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/rider_auth_provider.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;

  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateYAnimation;
  late Animation<double> _pulseAnimation;

  bool _hasNavigated = false;
  bool _minTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation matching React Native (1800ms)
    // Parallel: rotate (0 to 360), scale (0.3 to 1.0 spring), opacity (0 to 1 over 800ms), translateY (50 to 0 spring)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.25, 0.1, 0.25, 1.0),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 800 / 1800, curve: Curves.easeIn),
      ),
    );

    _translateYAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Continuous pulse animation for outer ring & background circles (1.0 -> 1.2 -> 1.0, 1000ms each way)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 3. Dots loop animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _entranceController.forward();

    // Minimum splash duration matching React Native: 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() => _minTimeElapsed = true);
        _tryNavigate();
      }
    });
  }

  Future<void> _tryNavigate() async {
    if (!mounted || _hasNavigated || !_minTimeElapsed) return;

    if (coreServicesInitFuture != null) {
      await coreServicesInitFuture;
    }

    if (!mounted) return;
    final auth = context.read<RiderAuthProvider>();
    if (auth.isLoading) {
      Future.delayed(const Duration(milliseconds: 200), _tryNavigate);
      return;
    }

    _hasNavigated = true;
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // React Native exact theme colors:
    // COLORS.primary: #2EC4B6, COLORS.darkAccent: #1A2E35, COLORS.secondary: #FF8C42
    const primaryColor = Color(0xFF2EC4B6);
    const darkAccentColor = Color(0xFF1A2E35);
    const secondaryColor = Color(0xFFFF8C42);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, darkAccentColor, primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated background circles (3 floating translucent circles)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final scale = _pulseAnimation.value;
                return Stack(
                  children: [
                    // Circle 0: width * 0.5, opacity 0.10, top 0.20, left -0.20
                    Positioned(
                      top: height * 0.20,
                      left: -width * 0.20,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: width * 0.50,
                          height: width * 0.50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                    ),
                    // Circle 1: width * 0.7, opacity 0.07, top 0.30, left -0.15
                    Positioned(
                      top: height * 0.30,
                      left: -width * 0.15,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: width * 0.70,
                          height: width * 0.70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                      ),
                    ),
                    // Circle 2: width * 0.9, opacity 0.04, top 0.40, left -0.10
                    Positioned(
                      top: height * 0.40,
                      left: -width * 0.10,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: width * 0.90,
                          height: width * 0.90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Main Content Container (Entrance animated with opacity & spring translateY)
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _translateYAnimation.value),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Outer & Inner Rings with Logo
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                          animation: _entranceController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotateAnimation.value,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.jpeg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.delivery_dining,
                                  size: 64,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Brand Text Section
                  const SizedBox(height: 40),
                  const Text(
                    'RobotInn Rider',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fastest Delivery Network',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // Animated 3 Dots
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: Listenable.merge([_entranceController, _dotsController]),
                    builder: (context, _) {
                      final entranceProgress = _opacityAnimation.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final wave = (_dotsController.value - (index * 0.25)) % 1.0;
                          final dotOpacity = (0.3 + (wave * 0.7)) * entranceProgress;
                          final dotScale = (0.7 + (wave * 0.5)) * entranceProgress.clamp(0.5, 1.0);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.scale(
                              scale: dotScale,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: dotOpacity.clamp(0.0, 1.0)),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer with Version & Copyright
            Positioned(
              bottom: 30,
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _translateYAnimation.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2024 RobotInn. All rights reserved.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
