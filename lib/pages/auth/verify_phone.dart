import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';
import 'package:store/pages/auth/registration_complete.dart';

class VerifyPhone extends StatefulWidget {
  const VerifyPhone({super.key});

  @override
  State<VerifyPhone> createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends State<VerifyPhone> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());

    _focusNodes = List.generate(4, (_) => FocusNode());

    _startTimer();
    for (final node in _focusNodes) {
      node.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.removeListener(_onFocusChanged);
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 10;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _resendCode() {
    if (_secondsRemaining > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait for the timer to expire.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verification code resent!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.success,
      ),
    );
    _startTimer();
  }

  void _onNextPressed() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the full 4-digit code',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const RegistrationComplete()),
    );
  }

  String _formatTime(int seconds) {
    final s = seconds.toString().padLeft(2, '0');
    return '00 : $s';
  }

  Widget _buildPinField(int index) {
    return SizedBox(
      width: 60,
      height: 62,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();

            setState(() {});

            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.labelPrimary,
          ),
          decoration: InputDecoration(
            counterText: "",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFC7C7CC),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
          onChanged: (value) {
            // Handle paste of multiple digits
            if (value.length > 1) {
              final chars = value.split('');

              for (
                int i = 0;
                i < chars.length && i < _controllers.length;
                i++
              ) {
                _controllers[i].text = chars[i];
              }

              _focusNodes.last.unfocus();
              setState(() {});
              return;
            }

            // Move forward when digit entered
            if (value.isNotEmpty) {
              if (index < _controllers.length - 1) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
              }
            }
            // Move backward when field becomes empty
            else {
              if (index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            }

            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFC7C7CC),
                                width: 1.2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Title
                      Text(
                        'Verification',
                        strutStyle: const StrutStyle(height: 1.2),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.labelPrimary,
                          height: 1.2,
                          letterSpacing: 0.38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        strutStyle: const StrutStyle(height: 1.33),
                        'Enter the 4 digit verification code sent to your mail or phone number .',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.miscellaneous,
                          height: 1.3,
                          letterSpacing: 0.18,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // PIN boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPinField(0),
                          const SizedBox(width: 12),
                          _buildPinField(1),
                          const SizedBox(width: 12),
                          _buildPinField(2),
                          const SizedBox(width: 12),
                          _buildPinField(3),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Timer
                      Center(
                        child: Text(
                          _formatTime(_secondsRemaining),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Retry link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't get verification? ",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.gray,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: _resendCode,
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _secondsRemaining > 0
                                    ? AppColors.blue.withValues(alpha: 0.4)
                                    : AppColors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      // Next Button
                      Center(
                        child: MyButton(
                          text: 'Next',
                          onPressed: _onNextPressed,
                          color: AppColors.buttonPrimary,
                          width: MediaQuery.sizeOf(context).width * 0.9,
                          height: 62,
                        ),
                      ),
                      const SizedBox(height: 16),
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
