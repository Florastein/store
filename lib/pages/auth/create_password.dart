import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/pages/auth/add_phone.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';
import '../../providers/repositories.dart';

class CreatePassword extends ConsumerStatefulWidget {
  const CreatePassword({super.key, this.name, this.email});

  final String? name;
  final String? email;

  @override
  ConsumerState<CreatePassword> createState() => _CreatePasswordState();
}

class _CreatePasswordState extends ConsumerState<CreatePassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _verifyPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _verifyPasswordFocusNode = FocusNode();
  bool _isPasswordObscured = true;
  bool _isVerifyPasswordObscured = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onTextChanged);
    _verifyPasswordController.addListener(_onTextChanged);
    _passwordFocusNode.addListener(_onFocusChanged);
    _verifyPasswordFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onTextChanged);
    _verifyPasswordController.removeListener(_onTextChanged);
    _passwordFocusNode.removeListener(_onFocusChanged);
    _verifyPasswordFocusNode.removeListener(_onFocusChanged);
    _passwordController.dispose();
    _verifyPasswordController.dispose();
    _passwordFocusNode.dispose();
    _verifyPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _snack(String message, Color color) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message, style: GoogleFonts.poppins()), backgroundColor: color));
  }

  void _showError(Object error) {
    String message = 'Something went wrong. Please try again.';
    if (error is FirebaseException) {
      switch (error.code) {
        case 'email-already-in-use':
          message = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
      }
    }
    _snack(message, AppColors.error);
  }

  Future<void> _onNextPressed() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final name = widget.name;
    final email = widget.email;
    if (name == null || email == null) {
      _snack('Missing account details. Please go back and try again.', AppColors.error);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: _passwordController.text,
            name: name,
          );
      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddPhone()),
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _hasLowercase(String password) => password.contains(RegExp('[a-z]'));

  bool _hasUppercase(String password) => password.contains(RegExp('[A-Z]'));

  bool _hasDigit(String password) => password.contains(RegExp('[0-9]'));

  bool _hasSpecialCharacter(String password) =>
      password.contains(RegExp(r'[!@#\$&*~]'));

  int _countPasswordCharacterClasses(String password) => [
    _hasLowercase(password),
    _hasUppercase(password),
    _hasDigit(password),
    _hasSpecialCharacter(password),
  ].where((hasClass) => hasClass).length;

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return 0;
    }

    final characterClasses = _countPasswordCharacterClasses(password);
    int score = 0;

    if (password.length >= 10) {
      score++;
    }
    if (password.length >= 14) {
      score++;
    }
    if (characterClasses >= 2) {
      score++;
    }
    if (characterClasses >= 3) {
      score++;
    }
    if (characterClasses == 4) {
      score++;
    }

    return score;
  }

  Widget _buildStrengthBar(int index, int filledBars, int score) {
    Color color;
    if (index >= filledBars) {
      color = const Color(0xFFE5E5EA); // Unfilled
    } else {
      if (score <= 1) {
        color = const Color(0xFFEA4335); // Red (Weak)
      } else if (score == 2) {
        color = const Color(0xFFFBBC05); // Orange (Fair)
      } else if (score <= 4) {
        color = const Color(0xFF81C784); // Light Green (Good)
      } else {
        // Strong
        color = index == 0 ? const Color(0xFFC2F4D2) : const Color(0xFF00C853);
      }
    }

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  String _getStrengthText(int score) {
    if (score <= 1) {
      return 'Weak';
    }
    if (score == 2) {
      return 'Fair';
    }
    if (score <= 4) {
      return 'Good';
    }
    return 'Strong';
  }

  Widget _buildStrengthIndicator() {
    final password = _passwordController.text;
    final score = _calculatePasswordStrength(password);
    if (score == 0) {
      return const SizedBox.shrink();
    }

    final filledBars = score <= 1
        ? 1
        : score == 2
        ? 2
        : score <= 4
        ? 3
        : 4;

    return Row(
      children: [
        Expanded(child: _buildStrengthBar(0, filledBars, score)),
        const SizedBox(width: 8),
        Expanded(child: _buildStrengthBar(1, filledBars, score)),
        const SizedBox(width: 8),
        Expanded(child: _buildStrengthBar(2, filledBars, score)),
        const SizedBox(width: 8),
        Expanded(child: _buildStrengthBar(3, filledBars, score)),
        const SizedBox(width: 12),
        Text(
          _getStrengthText(score),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF595959),
          ),
        ),
      ],
    );
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
                    // Circular Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_circle_left_outlined,
                          size: 40,
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Create Password',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.labelPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Enter a strong password',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.miscellaneous,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Password Label
                    Text(
                      'Password',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Password Input
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
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _isPasswordObscured,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.labelPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: '',
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          isPasswordField: true,
                          isObscured: _isPasswordObscured,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 10) {
                            return 'Password must be at least 10 characters';
                          }
                          if (_countPasswordCharacterClasses(value) < 3) {
                            return 'Use upper and lower case letters, numbers, and symbols';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Verify Password Label
                    Text(
                      'Verify password',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Verify Password Input
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
                        controller: _verifyPasswordController,
                        focusNode: _verifyPasswordFocusNode,
                        obscureText: _isVerifyPasswordObscured,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.labelPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: '',
                          controller: _verifyPasswordController,
                          focusNode: _verifyPasswordFocusNode,
                          isPasswordField: true,
                          isObscured: _isVerifyPasswordObscured,
                          onToggleVisibility: () {
                            setState(() {
                              _isVerifyPasswordObscured =
                                  !_isVerifyPasswordObscured;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please verify your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStrengthIndicator(),
                    const Spacer(),
                    const SizedBox(height: 32),
                    // Terms and Conditions
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.miscellaneous,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.labelPrimary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Handle Terms link press
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Conditions',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.labelPrimary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                // Handle Conditions link press
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Next Button
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
    bool isPasswordField = false,
    bool isObscured = true,
    VoidCallback? onToggleVisibility,
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
    suffixIcon: (focusNode.hasFocus || controller.text.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                    },
                    child: const Icon(
                      Icons.cancel,
                      color: Color(0xFFBCBCBC),
                      size: 20,
                    ),
                  ),
                if (isPasswordField) const SizedBox(width: 8),
                if (isPasswordField)
                  GestureDetector(
                    onTap: onToggleVisibility,
                    child: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFBCBCBC),
                      size: 20,
                    ),
                  ),
              ],
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
