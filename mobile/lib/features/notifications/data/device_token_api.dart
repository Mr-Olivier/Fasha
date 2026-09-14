import 'package:dio/dio.dart';

/// Raw HTTP calls to /api/device-tokens - registers/unregisters this
/// install for push notifications (see PushNotificationService, mobile
/// and backend). `platform` is a plain string on this side ("ANDROID" or
/// "WEB") rather than a shared enum with the backend - it's the one value
/// this whole feature sends, not worth a cross-cutting domain type for.
class DeviceTokenApi {
  const DeviceTokenApi(this._dio);

  final Dio _dio;

  Future<void> register({required String token, required String platform}) =>
      _dio.post<void>('/device-tokens', data: {'token': token, 'platform': platform});

  Future<void> unregister(String token) => _dio.delete<void>('/device-tokens/$token');
}
