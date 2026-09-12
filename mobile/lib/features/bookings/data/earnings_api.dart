import 'package:dio/dio.dart';

import '../domain/completed_job.dart';
import '../domain/earnings_summary.dart';

/// Raw HTTP calls to GET /api/providers/me/earnings and .../completed-jobs.
class EarningsApi {
  const EarningsApi(this._dio);

  final Dio _dio;

  Future<EarningsSummary> getSummary(String period) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/providers/me/earnings',
      queryParameters: {'period': period},
    );
    return EarningsSummary.fromJson(response.data!);
  }

  Future<List<CompletedJob>> listCompletedJobs(String period) async {
    final response = await _dio.get<List<dynamic>>(
      '/providers/me/completed-jobs',
      queryParameters: {'period': period},
    );
    return response.data!.map((e) => CompletedJob.fromJson(e as Map<String, dynamic>)).toList();
  }
}
