import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/booking_photo.dart';

/// Raw HTTP calls to POST/GET /api/bookings/{bookingId}/photos - metadata
/// only. Actual bytes are fetched separately by SecureNetworkImage.
class BookingPhotoApi {
  const BookingPhotoApi(this._dio);

  final Dio _dio;

  Future<List<BookingPhoto>> list(String bookingId) async {
    final response = await _dio.get<List<dynamic>>('/bookings/$bookingId/photos');
    return response.data!.map((e) => BookingPhoto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookingPhoto> upload(String bookingId, XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _dio.post<Map<String, dynamic>>('/bookings/$bookingId/photos', data: formData);
    return BookingPhoto.fromJson(response.data!);
  }
}
