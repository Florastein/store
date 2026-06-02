import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/pages/splash/splash_two.dart';
import 'package:store/theme/app_colors.dart';

class SplashOne extends StatefulWidget {
  const SplashOne({super.key});

  @override
  State<SplashOne> createState() => _SplashOneState();
}

class _SplashOneState extends State<SplashOne>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _opacityAnimation = Tween<double>(
      begin: 0.1,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextScreen();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextScreen() {
    if (_hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const SplashTwo()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Text(
            "S",
            style: GoogleFonts.poppins(
              fontSize: 148,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
