import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  );

  Future<void> sendPasswordReset(String email);

  Future<void> updateProfile({String? name});

  Future<void> signOut();
}
