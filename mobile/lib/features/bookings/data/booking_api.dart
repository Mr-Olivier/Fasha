import 'package:dio/dio.dart';

import '../domain/booking.dart';

/// Raw HTTP calls to POST/GET /api/bookings and its PATCH transition
/// endpoints (accept/reject/start/complete/cancel).
class BookingApi {
  const BookingApi(this._dio);

  final Dio _dio;

  Future<Booking> create({required String serviceListingId, String? note, DateTime? requestedDate}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bookings',
      data: {
        'serviceListingId': serviceListingId,
        'note': note,
        'requestedDate': requestedDate != null ? _formatDate(requestedDate) : null,
      },
    );
    return Booking.fromJson(response.data!);
  }

  Future<List<Booking>> listForCustomer() => _list('customer');

  Future<List<Booking>> listForProvider() => _list('provider');

  Future<Booking> accept(String bookingId) => _transition(bookingId, 'accept');

  Future<Booking> reject(String bookingId) => _transition(bookingId, 'reject');

  Future<Booking> start(String bookingId) => _transition(bookingId, 'start');

  Future<Booking> complete(String bookingId) => _transition(bookingId, 'complete');

  Future<Booking> cancel(String bookingId) => _transition(bookingId, 'cancel');

  Future<List<Booking>> _list(String role) async {
    final response = await _dio.get<List<dynamic>>('/bookings', queryParameters: {'role': role});
    return response.data!.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> _transition(String bookingId, String action) async {
    final response = await _dio.patch<Map<String, dynamic>>('/bookings/$bookingId/$action');
    return Booking.fromJson(response.data!);
  }

  /// The backend's `requestedDate` is a plain LocalDate ("YYYY-MM-DD") -
  /// DateTime.toIso8601String() would include a time component Jackson's
  /// LocalDate deserializer rejects, so this formats it by hand instead.
  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
