import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:store/pages/customer/dashboard.dart';
import 'package:store/theme/app_colors.dart';

class RegistrationComplete extends StatefulWidget {
  const RegistrationComplete({super.key});

  @override
  State<RegistrationComplete> createState() => _RegistrationCompleteState();
}

class _RegistrationCompleteState extends State<RegistrationComplete> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _scheduleNavigation(Duration animationDuration) {
    _navigationTimer?.cancel();
    _navigationTimer = Timer(
      animationDuration + const Duration(seconds: 1),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CustomerDashboard()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/ann.json',
                width: MediaQuery.sizeOf(context).width * 0.8,
                height: MediaQuery.sizeOf(context).height * 0.3,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _scheduleNavigation(composition.duration);
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Congratulations!',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.labelPrimary,
                  letterSpacing: 0.38,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are all set.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.miscellaneous,
                  letterSpacing: 0.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
