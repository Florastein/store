import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store/pages/customer/dashboard.dart';
import 'package:store/providers/repositories.dart';
import 'package:store/theme/app_colors.dart';
import 'package:store/widgets/mybutton.dart';

class VerifyPhone extends ConsumerStatefulWidget {
  const VerifyPhone({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    super.key,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  @override
  ConsumerState<VerifyPhone> createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends ConsumerState<VerifyPhone> {
  final _codeController = TextEditingController();
  late String _verificationId = widget.verificationId;
  int? _resendToken;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _resendToken = widget.resendToken;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isSubmitting || _codeController.text.length != 6) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPhoneCode(
            verificationId: _verificationId,
            smsCode: _codeController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerDashboard()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'The verification code is invalid.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    await ref
        .read(authRepositoryProvider)
        .verifyPhoneNumber(
          phoneNumber: widget.phoneNumber,
          forceResendingToken: _resendToken,
          verificationCompleted: (credential) async => ref
              .read(authRepositoryProvider)
              .signInWithPhoneCredential(credential),
          verificationFailed: (error) =>
              _showError(error.message ?? 'Unable to resend the code.'),
          codeSent: (verificationId, resendToken) {
            if (!mounted) {
              return;
            }
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A new SMS code was sent.')),
            );
          },
          codeAutoRetrievalTimeout: (verificationId) =>
              _verificationId = verificationId,
        );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
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
              'Verify your phone',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the 6-digit SMS code sent to ${widget.phoneNumber}.',
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
            TextButton(
              onPressed: _resend,
              child: const Text('Resend SMS code'),
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
