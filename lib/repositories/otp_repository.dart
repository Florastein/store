import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:store/repositories/interfaces/otp_repository.dart';

typedef TurnstileTokenProvider = Future<String?> Function();
typedef DeviceFingerprintProvider = Future<String> Function();

class OtpRepositoryImpl implements OtpRepository {
  OtpRepositoryImpl({
    required Uri baseUrl,
    required TurnstileTokenProvider turnstileTokenProvider,
    required DeviceFingerprintProvider deviceFingerprintProvider,
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _turnstileTokenProvider = turnstileTokenProvider,
       _deviceFingerprintProvider = deviceFingerprintProvider,
       _client = client ?? http.Client();

  final Uri _baseUrl;
  final TurnstileTokenProvider _turnstileTokenProvider;
  final DeviceFingerprintProvider _deviceFingerprintProvider;
  final http.Client _client;

  @override
  Future<void> sendOtp({
    required String email,
    required OtpPurpose purpose,
    String? name,
  }) async {
    final token = await _turnstileTokenProvider();
    final deviceFingerprint = await _deviceFingerprintProvider();
    await _post('/send-otp', {
      'email': email.trim(),
      'purpose': purpose.apiValue,
      'deviceFingerprint': deviceFingerprint,
      if (token != null && token.trim().isNotEmpty) 'turnstileToken': token,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
  }

  @override
  Future<String> verifyOtp({
    required String email,
    required String otp,
    required OtpPurpose purpose,
  }) async {
    final body = await _post('/verify-otp', {
      'email': email.trim(),
      'otp': otp.trim(),
      'purpose': purpose.apiValue,
    });
    final proof = body['proof'];
    if (proof is! String || proof.isEmpty) {
      throw const OtpException(
        'The server returned an invalid verification response.',
      );
    }
    return proof;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    http.Response response;
    try {
      response = await _client.post(
        _baseUrl.resolve(path),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );
    } on Exception {
      throw const OtpException('Unable to reach the verification server.');
    }

    Map<String, dynamic> body = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } on FormatException {
      // The status-based fallback below is more useful than a parsing error.
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OtpException(
        body['message'] as String? ??
            body['error'] as String? ??
            'Verification request failed. Please try again.',
      );
    }
    return body;
  }
}
