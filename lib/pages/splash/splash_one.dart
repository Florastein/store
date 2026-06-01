import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashOne extends StatelessWidget {
  const SplashOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.1, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Text(
            "S",
            style: GoogleFonts.poppins(
              fontSize: 148,
              fontWeight: FontWeight.bold,
            ),
          ),
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
        ),
      ),
    );
  }
}
