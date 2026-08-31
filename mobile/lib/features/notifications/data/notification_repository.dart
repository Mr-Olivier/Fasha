import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/app_notification.dart';
import 'notification_api.dart';

class NotificationRepository {
  const NotificationRepository(this._api);

  final NotificationApi _api;

  Future<List<AppNotification>> list() async {
    try {
      return await _api.list();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.markRead(id);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markAllRead();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
