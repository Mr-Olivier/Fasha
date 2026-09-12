import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/booking_photo.dart';
import 'booking_photo_api.dart';

class BookingPhotoRepository {
  const BookingPhotoRepository(this._api);

  final BookingPhotoApi _api;

  Future<List<BookingPhoto>> list(String bookingId) => _guard(() => _api.list(bookingId));

  Future<BookingPhoto> upload(String bookingId, XFile image) => _guard(() => _api.upload(bookingId, image));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
