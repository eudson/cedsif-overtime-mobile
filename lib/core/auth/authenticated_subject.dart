import 'package:cedsif_overtime_mobile/core/storage/secure_storage.dart';
import 'package:cedsif_overtime_mobile/core/utils/jwt_decoder.dart';

abstract final class AuthenticatedRequestContext {
  static const expectedSubjectKey = 'expected_auth_subject';

  static String? subjectFromBearerHeader(Object? header) {
    if (header is! String || !header.startsWith('Bearer ')) {
      return null;
    }
    final subject = JwtDecoder.decode(
      header.substring('Bearer '.length),
    )?['sub'];
    return subject is String && subject.isNotEmpty ? subject : null;
  }
}

abstract final class AuthenticatedSubject {
  static Future<String?> read(SecureStorage secureStorage) async {
    return (await AuthenticatedToken.read(secureStorage))?.subject;
  }
}

class AuthenticatedToken {
  const AuthenticatedToken({required this.accessToken, required this.subject});

  final String accessToken;
  final String subject;

  static Future<AuthenticatedToken?> read(SecureStorage secureStorage) async {
    try {
      final token = await secureStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      final subject = JwtDecoder.decode(token)?['sub'];
      return subject is String && subject.isNotEmpty
          ? AuthenticatedToken(accessToken: token, subject: subject)
          : null;
    } on Object {
      return null;
    }
  }
}
