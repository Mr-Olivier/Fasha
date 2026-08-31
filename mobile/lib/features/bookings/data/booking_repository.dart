import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/booking.dart';
import 'booking_api.dart';

/// Adds error handling on top of BookingApi - same split as every other
/// feature's *Repository (see AuthRepository's doc comment for why).
class BookingRepository {
  const BookingRepository(this._api);

  final BookingApi _api;

  Future<Booking> create({required String serviceListingId, String? note, DateTime? requestedDate}) =>
      _guard(() => _api.create(serviceListingId: serviceListingId, note: note, requestedDate: requestedDate));

  Future<List<Booking>> listForCustomer() => _guard(_api.listForCustomer);

  Future<List<Booking>> listForProvider() => _guard(_api.listForProvider);

  Future<Booking> accept(String bookingId) => _guard(() => _api.accept(bookingId));

  Future<Booking> reject(String bookingId) => _guard(() => _api.reject(bookingId));

  Future<Booking> start(String bookingId) => _guard(() => _api.start(bookingId));

  Future<Booking> complete(String bookingId) => _guard(() => _api.complete(bookingId));

  Future<Booking> cancel(String bookingId) => _guard(() => _api.cancel(bookingId));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
