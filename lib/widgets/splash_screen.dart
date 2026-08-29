import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2300), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04110D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF04110D), Color(0xFF0B211A), Color(0xFF04110D)],
          ),
        ),
        child: Align(
          alignment: const Alignment(0, 0.15),
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE3C46B).withValues(alpha: 0.35),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Image.asset(
                        'assets/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E8A6D),
                            borderRadius: BorderRadius.circular(34),
                          ),
                          child: const Icon(Icons.mosque_rounded,
                              color: Colors.white, size: 64),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    AppConfig.appName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFF4EDDC),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE3C46B), Color(0xFF0E8A6D)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اذان • نماز • قبلہ',
                    style: TextStyle(
                      color: const Color(0xFFE3C46B).withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}