import 'package:dio/dio.dart';

import '../domain/admin_stats.dart';
import '../domain/booking_trend_point.dart';
import '../domain/user_growth_point.dart';

/// Raw HTTP calls to /api/admin/stats/* - admin-only, enforced server-side
/// by @PreAuthorize("hasRole('ADMIN')") on AdminStatsController.
class AdminStatsApi {
  const AdminStatsApi(this._dio);

  final Dio _dio;

  Future<AdminStats> getStats() async {
    final response = await _dio.get<Map<String, dynamic>>('/admin/stats');
    return AdminStats.fromJson(response.data!);
  }

  Future<List<BookingTrendPoint>> getBookingsTrend({int days = 30}) async {
    final response = await _dio.get<List<dynamic>>('/admin/stats/bookings-trend', queryParameters: {'days': days});
    return response.data!.map((e) => BookingTrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserGrowthPoint>> getUserGrowth({int weeks = 12}) async {
    final response = await _dio.get<List<dynamic>>('/admin/stats/user-growth', queryParameters: {'weeks': weeks});
    return response.data!.map((e) => UserGrowthPoint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
