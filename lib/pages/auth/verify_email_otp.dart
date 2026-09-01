import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/providers/repositories.dart';
import 'package:store/repositories/interfaces/otp_repository.dart';
import 'package:store/theme/app_colors.dart';

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

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes : $seconds';
  }

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
    body: SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 18,
            top: 18,
            child: Semantics(
              button: true,
              label: 'Go back',
              child: InkWell(
                onTap: () => Navigator.maybePop(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF96979C),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 30,
                    color: Color(0xFF8C8D92),
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Verification',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF292929),
                      fontSize: 44,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Enter the 6 digit verification code sent to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF89898B),
                      fontSize: 19,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 56),
                  _OtpCodeInput(
                    controller: _codeController,
                    enabled: !_isSubmitting,
                    onChanged: (value) {
                      setState(() {});
                      if (value.length == 6) {
                        _verify();
                      }
                    },
                  ),
                  const SizedBox(height: 34),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isSubmitting
                        ? const SizedBox(
                            key: ValueKey('progress'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _formattedTime,
                            key: ValueKey(_formattedTime),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF858588),
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Didn’t get verification?',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF858588),
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _secondsRemaining == 0 && !_isResending
                            ? _resend
                            : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: const Color(0xFF6B9DFF),
                          disabledForegroundColor: const Color(
                            0xFF6B9DFF,
                          ).withValues(alpha: 0.45),
                        ),
                        child: Text(
                          _isResending ? 'Sending…' : 'Retry',
                          style: GoogleFonts.poppins(fontSize: 17),
                        ),
                      ),
                    ],
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

class _OtpCodeInput extends StatelessWidget {
  const _OtpCodeInput({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final cellWidth = ((constraints.maxWidth - (gap * 5)) / 6).clamp(
        42.0,
        58.0,
      );

      return Semantics(
        label: '6 digit verification code',
        textField: true,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final digit = index < controller.text.length
                    ? controller.text[index]
                    : '';
                final isActive = index == controller.text.length && enabled;
                return Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: cellWidth,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF68696D)
                            : const Color(0xFF96979C),
                        width: isActive ? 1.8 : 1.4,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF292929),
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: TextField(
                controller: controller,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                cursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
    },
  );
}
