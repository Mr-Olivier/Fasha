import 'package:dio/dio.dart';

import '../domain/app_notification.dart';

/// Raw HTTP calls to /api/notifications. No push wiring (no FCM) - the app
/// just polls this like every other list screen (see NotificationService's
/// doc comment on the backend for why).
class NotificationApi {
  const NotificationApi(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> list() async {
    final response = await _dio.get<List<dynamic>>('/notifications');
    return response.data!.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) => _dio.patch<void>('/notifications/$id/read');

  Future<void> markAllRead() => _dio.patch<void>('/notifications/read-all');
}
