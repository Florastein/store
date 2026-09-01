import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mybutton.dart';
import '../../providers/repositories.dart';

class ForgotPassword extends ConsumerStatefulWidget {
  const ForgotPassword({super.key});

  @override
  ConsumerState<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends ConsumerState<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
    _emailFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextChanged);
    _emailFocusNode.removeListener(_onFocusChanged);
    _emailController.dispose();
    _emailFocusNode.dispose();
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

  Future<void> _onResetPressed() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordReset(_emailController.text);
      if (!mounted) {
        return;
      }
      _snack('Password reset link sent to your email.', AppColors.success);
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _snack('No account found with this email.', AppColors.error);
          break;
        case 'invalid-email':
          _snack('Please enter a valid email address.', AppColors.error);
          break;
        default:
          _snack(
            'Something went wrong. Please try again.',
            AppColors.error,
          );
      }
    } catch (_) {
      _snack('Something went wrong. Please try again.', AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
                      'Forgot Password',
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
                      'Enter your email and we will send you a link to reset your password.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.miscellaneous,
                        height: 1.3,
                        letterSpacing: 0.18,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Email',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: AppColors.labelPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'example@mail.com',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textTetiary,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          errorStyle: const TextStyle(fontSize: 0, height: 0),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon:
                              (_emailFocusNode.hasFocus &&
                                  _emailController.text.isNotEmpty)
                              ? GestureDetector(
                                  onTap: () {
                                    _emailController.clear();
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
                            borderSide: const BorderSide(color: AppColors.gray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          final emailRegExp = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegExp.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 32),
                    Center(
                      child: MyButton(
                        text: 'Send Reset Link',
                        onPressed: _onResetPressed,
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
}
