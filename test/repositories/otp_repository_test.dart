import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:store/repositories/interfaces/otp_repository.dart';
import 'package:store/repositories/otp_repository.dart';

void main() {
  test('sendOtp sends the server contract', () async {
    late Map<String, dynamic> requestBody;
    final repository = OtpRepositoryImpl(
      baseUrl: Uri.parse('https://otp.example.com'),
      turnstileTokenProvider: () async => 'token',
      client: MockClient((request) async {
        expect(request.url.path, '/send-otp');
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('{"success":true}', 200);
      }),
    );

    await repository.sendOtp(
      email: ' user@example.com ',
      name: 'User',
      purpose: OtpPurpose.login,
    );

    expect(requestBody, {
      'email': 'user@example.com',
      'name': 'User',
      'purpose': 'login',
      'turnstileToken': 'token',
    });
  });

  test('verifyOtp returns the signed proof', () async {
    final repository = OtpRepositoryImpl(
      baseUrl: Uri.parse('https://otp.example.com'),
      turnstileTokenProvider: () async => 'token',
      client: MockClient(
        (_) async => http.Response('{"success":true,"proof":"signed"}', 200),
      ),
    );

    final proof = await repository.verifyOtp(
      email: 'user@example.com',
      otp: '123456',
      purpose: OtpPurpose.emailConfirmation,
    );

    expect(proof, 'signed');
  });

  test('surfaces the server error message', () async {
    final repository = OtpRepositoryImpl(
      baseUrl: Uri.parse('https://otp.example.com'),
      turnstileTokenProvider: () async => 'token',
      client: MockClient(
        (_) async => http.Response('{"error":"Invalid code"}', 400),
      ),
    );

    expect(
      () => repository.verifyOtp(
        email: 'user@example.com',
        otp: '000000',
        purpose: OtpPurpose.login,
      ),
      throwsA(
        isA<OtpException>().having(
          (error) => error.message,
          'message',
          'Invalid code',
        ),
      ),
    );
  });
}
