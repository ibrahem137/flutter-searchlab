import 'package:dio/dio.dart';

String catalogFailureMessage(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout =>
      'The request timed out. Please retry.',
    DioExceptionType.connectionError =>
      'Unable to connect. Check offline mode and retry.',
    DioExceptionType.badResponse =>
      'The catalog could not complete the request. Please retry.',
    DioExceptionType.badCertificate => 'The connection could not be verified.',
    DioExceptionType.cancel => 'Request cancelled.',
    DioExceptionType.unknown => 'Unable to load books. Please retry.',
  };
}
