import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/completed_job.dart';
import '../domain/earnings_summary.dart';
import 'earnings_api.dart';

class EarningsRepository {
  const EarningsRepository(this._api);

  final EarningsApi _api;

  Future<EarningsSummary> getSummary(String period) => _guard(() => _api.getSummary(period));

  Future<List<CompletedJob>> listCompletedJobs(String period) => _guard(() => _api.listCompletedJobs(period));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
