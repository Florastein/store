import 'package:firebase_auth/firebase_auth.dart';
import 'interfaces/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateProfile(displayName: name);
    return credential;
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) => _firebaseAuth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) => _firebaseAuth.verifyPhoneNumber(
    phoneNumber: phoneNumber.trim(),
    verificationCompleted: verificationCompleted,
    verificationFailed: verificationFailed,
    codeSent: codeSent,
    codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    forceResendingToken: forceResendingToken,
  );

  @override
  Future<UserCredential> signInWithPhoneCode({
    required String verificationId,
    required String smsCode,
  }) => _firebaseAuth.signInWithCredential(
    PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    ),
  );

  @override
  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) => _firebaseAuth.signInWithCredential(credential);

  @override
  Future<void> sendPasswordReset(String email) =>
      _firebaseAuth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> updateProfile({String? name}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateProfile(displayName: name);
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();
}
