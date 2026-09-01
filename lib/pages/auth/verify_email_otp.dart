import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/providers/repositories.dart';
import 'package:store/repositories/interfaces/otp_repository.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';

class VerifyEmailOtp extends ConsumerStatefulWidget {
  const VerifyEmailOtp({
    required this.email,
    required this.purpose,
    required this.onVerified,
    this.name,
    super.key,
  });

  final String email;
  final String? name;
  final OtpPurpose purpose;
  final Future<void> Function() onVerified;

  @override
  ConsumerState<VerifyEmailOtp> createState() => _VerifyEmailOtpState();
}

class _VerifyEmailOtpState extends ConsumerState<VerifyEmailOtp> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  void _showError(Object error) {
    final message = error is OtpException
        ? error.message
        : 'Verification failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _verify() async {
    if (_isSubmitting || _codeController.text.length != 6) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(otpRepositoryProvider)
          .verifyOtp(
            email: widget.email,
            otp: _codeController.text,
            purpose: widget.purpose,
          );
      await widget.onVerified();
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isResending) {
      return;
    }
    setState(() => _isResending = true);
    try {
      await ref
          .read(otpRepositoryProvider)
          .sendOtp(
            email: widget.email,
            name: widget.name,
            purpose: widget.purpose,
          );
      if (!mounted) {
        return;
      }
      setState(_startTimer);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('A new code was sent.')));
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundColor,
    appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Check your email',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the 6-digit code sent to ${widget.email}.',
              style: GoogleFonts.poppins(color: AppColors.miscellaneous),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.length == 6) {
                  _verify();
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _secondsRemaining == 0 ? _resend : null,
              child: Text(
                _secondsRemaining > 0
                    ? 'Resend in ${_secondsRemaining}s'
                    : 'Resend code',
              ),
            ),
            const Spacer(),
            MyButton(
              text: _isSubmitting ? 'Verifying...' : 'Verify',
              onPressed: _isSubmitting ? () {} : _verify,
              color: AppColors.buttonPrimary,
              width: double.infinity,
            ),
          ],
        ),
      ),
    ),
  );
}
