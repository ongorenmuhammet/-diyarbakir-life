import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashLocationScreen extends StatefulWidget {
  const SplashLocationScreen({super.key});

  @override
  State<SplashLocationScreen> createState() => _SplashLocationScreenState();
}

class _SplashLocationScreenState extends State<SplashLocationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.65, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    _controller.forward();
    _startLoading();
  }

  void _startLoading() {
    const totalSteps = 40;
    final stepDuration = const Duration(milliseconds: 80);
    int currentStep = 0;

    _progressTimer = Timer.periodic(stepDuration, (timer) async {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = currentStep / totalSteps;
        });
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _navigateToNext();
      }
    });
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('prefs timeout'),
      );
      final hasDistrict = prefs.containsKey('selected_district');
      if (mounted) {
        if (hasDistrict) {
          context.go('/home');
        } else {
          context.go('/welcome');
        }
      }
    } catch (_) {
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      // Glowing Backdrop behind Logo
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB300).withOpacity(0.18),
                                  blurRadius: 75,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00B0FF).withOpacity(0.08),
                                  blurRadius: 90,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(110),
                            child: Image.asset(
                              'assets/logo.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                'logo.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 200,
                                  height: 200,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E1E1E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '21',
                                      style: TextStyle(
                                        color: Color(0xFFFFB300),
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      // Title Text
                      const Text(
                        'Diyarbakır Life',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        'Geleceğin Akıllı Şehir Rehberi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(flex: 2),
                      // Circular spinning loader with subtle glow
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 3.5,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Yükleniyor...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}