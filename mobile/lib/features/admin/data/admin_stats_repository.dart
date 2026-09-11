import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/admin_stats.dart';
import '../domain/booking_trend_point.dart';
import '../domain/user_growth_point.dart';
import 'admin_stats_api.dart';

class AdminStatsRepository {
  const AdminStatsRepository(this._api);

  final AdminStatsApi _api;

  Future<AdminStats> getStats() async {
    try {
      return await _api.getStats();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<BookingTrendPoint>> getBookingsTrend({int days = 30}) async {
    try {
      return await _api.getBookingsTrend(days: days);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<UserGrowthPoint>> getUserGrowth({int weeks = 12}) async {
    try {
      return await _api.getUserGrowth(weeks: weeks);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
