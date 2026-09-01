import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:store/repositories/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseAuth mockFirebaseAuth;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    repository = AuthRepositoryImpl(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthRepositoryImpl', () {
    test('authStateChanges exposes the firebase auth stream', () {
      when(() => mockFirebaseAuth.authStateChanges())
          .thenAnswer((_) => const Stream.empty());

      expect(repository.authStateChanges, isA<Stream<User?>>());
      verify(() => mockFirebaseAuth.authStateChanges()).called(1);
    });

    test('currentUser returns the firebase current user', () {
      final user = MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(user);

      expect(repository.currentUser, same(user));
    });

    test('signUpWithEmail creates user, updates profile and returns credential',
        () async {
      final user = MockUser();
      final credential = MockUserCredential();
      when(
        () => user.updateProfile(displayName: any(named: 'displayName')),
      ).thenAnswer((_) async {});
      when(() => credential.user).thenReturn(user);

      when(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final result = await repository.signUpWithEmail(
        email: '  test@example.com  ',
        password: 'StrongPass123!',
        name: 'Jane Doe',
      );

      expect(result, same(credential));
      verify(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'StrongPass123!',
        ),
      ).called(1);
      verify(() => user.updateProfile(displayName: 'Jane Doe')).called(1);
    });

    test('signInWithEmail trims the email', () async {
      final credential = MockUserCredential();
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);

      final result = await repository.signInWithEmail(
        email: '  user@example.com ',
        password: 'password',
      );

      expect(result, same(credential));
      verify(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'user@example.com',
          password: 'password',
        ),
      ).called(1);
    });

    test('sendPasswordReset trims the email', () async {
      when(
        () => mockFirebaseAuth.sendPasswordResetEmail(
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {});

      await repository.sendPasswordReset(' reset@example.com ');

      verify(
        () => mockFirebaseAuth.sendPasswordResetEmail(
          email: 'reset@example.com',
        ),
      ).called(1);
    });

    test('signOut calls firebase sign out', () async {
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
    });
  });
}
