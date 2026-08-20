abstract final class ApiEndpoints {
  static const String health = '/health';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String employeeProfile = '/api/v1/me';
  static const String overtimeStart = '/api/v1/overtime/start';
  static const String overtimeEnd = '/api/v1/overtime/end';
  static const String overtimeHistory = '/api/v1/overtime/history';
  static const String overtimeSubmit = '/api/v1/overtime/submit';
}
