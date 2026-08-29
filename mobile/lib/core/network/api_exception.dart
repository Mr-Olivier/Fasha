import 'package:dio/dio.dart';

/// A clean, UI-friendly error thrown for any failed API call.
///
/// The backend's GlobalExceptionHandler always responds with the same JSON
/// shape on failure: {timestamp, status, error, message, details}. Instead
/// of every screen having to know that shape, we convert it once here -
/// screens just read [message] and show it directly.
class ApiException implements Exception {
  const ApiException(this.message, {this.details = const []});

  final String message;
  final List<String> details;

  /// Converts a Dio failure into an ApiException.
  ///
  /// [DioException] covers two very different situations, and we want a
  /// sensible message either way:
  ///  - the server responded, but with an error status (4xx/5xx) - we read
  ///    our backend's own error message out of the response body.
  ///  - the request never got a response at all (no internet, server down,
  ///    timeout) - there's no body to read, so we fall back to a generic
  ///    connectivity message.
  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      final rawDetails = data['details'];
      final details = rawDetails is List ? rawDetails.whereType<String>().toList() : const <String>[];
      return ApiException(data['message'] as String, details: details);
    }
    return const ApiException('Could not reach the server. Check your connection and try again.');
  }

  @override
  String toString() => details.isEmpty ? message : '$message ${details.join(' ')}';
}
