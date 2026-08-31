import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';
import 'package:store/pages/auth/verify_phone.dart';

class AddPhone extends StatefulWidget {
  const AddPhone({super.key});

  @override
  State<AddPhone> createState() => _AddPhoneState();
}

class _AddPhoneState extends State<AddPhone> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  static const Map<String, String> _countryFlagsByPrefix = {
    '233': '🇬🇭',
    '234': '🇳🇬',
    '254': '🇰🇪',
    '255': '🇹🇿',
    '256': '🇺🇬',
    '27': '🇿🇦',
    '33': '🇫🇷',
    '39': '🇮🇹',
    '44': '🇬🇧',
    '49': '🇩🇪',
    '61': '🇦🇺',
    '81': '🇯🇵',
    '91': '🇮🇳',
    '212': '🇲🇦',
    '213': '🇩🇿',
    '216': '🇹🇳',
  };

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onTextChanged);
    _phoneFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onTextChanged);
    _phoneFocusNode.removeListener(_onFocusChanged);
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  String _normalizedDialString(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      return cleaned.substring(1);
    }

    if (cleaned.startsWith('00')) {
      return cleaned.substring(2);
    }

    return cleaned;
  }

  String? _countryPrefixForPhoneNumber(String phoneNumber) {
    final normalizedPhoneNumber = _normalizedDialString(phoneNumber);
    final prefixes = _countryFlagsByPrefix.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final prefix in prefixes) {
      if (normalizedPhoneNumber.startsWith(prefix)) {
        return prefix;
      }
    }

    return null;
  }

  String _flagForPhoneNumber(String phoneNumber) {
    final prefix = _countryPrefixForPhoneNumber(phoneNumber);

    if (prefix != null) {
      return _countryFlagsByPrefix[prefix]!;
    }

    return '🌍';
  }

  void _showConfirmationDialog(String phoneNumber) {
    final countryFlag = _flagForPhoneNumber(phoneNumber);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (context) => Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.35),
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: 24,
                      ),
                      child: Text(
                        'Is this correct?',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.labelPrimary,
                        ),
                      ),
                    ),
                    Container(
                      //width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 19),
                      decoration: BoxDecoration(
                        color: AppColors.gray.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countryFlag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              phoneNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                color: AppColors.labelPrimary,
                                letterSpacing: -0.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyButton(
                          text: 'Edit',
                          fontWeight: FontWeight.w500,
                          textColor: AppColors.labelPrimary,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          color: AppColors.gray.withValues(alpha: 0.25),
                          width: 168,
                          height: 54,
                        ),
                        const SizedBox(width: 16),
                        MyButton(
                          text: 'Yes',
                          fontWeight: FontWeight.w500,
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const VerifyPhone(),
                              ),
                            );
                          },
                          color: AppColors.buttonPrimary,
                          width: 168,
                          height: 54,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  void _onNextPressed() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      _showConfirmationDialog(_phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
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
                        Text(
                          'Phone Number',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.labelPrimary,
                            height: 1.2,
                            letterSpacing: 0.38,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please enter your phone number in addition with your country code',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.miscellaneous,
                            height: 1.3,
                            letterSpacing: 0.18,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F4F0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.labelPrimary,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'Ex: (+233) 000-0000-00',
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final digitsOnly = value.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              if (digitsOnly.length < 7) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 32),
                        Center(
                          child: MyButton(
                            text: 'Next',
                            onPressed: _onNextPressed,
                            color: AppColors.buttonPrimary,
                            width: MediaQuery.sizeOf(context).width * 0.9,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ),
      ),
    );

  InputDecoration _buildInputDecoration({
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) => InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFFBCBCBC),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      isDense: true,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: (focusNode.hasFocus && controller.text.isNotEmpty)
          ? GestureDetector(
              onTap: () {
                controller.clear();
              },
              child: const Icon(
                Icons.cancel,
                color: Color(0xFFBCBCBC),
                size: 20,
              ),
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D1D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
}
