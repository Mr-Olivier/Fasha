import 'package:dio/dio.dart';

import '../domain/app_notification.dart';

/// Raw HTTP calls to /api/notifications - the in-app notification LIST
/// (what NotificationsScreen polls to render). Actual push delivery is a
/// separate concern, handled by PushNotificationService/DeviceTokenApi.
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
