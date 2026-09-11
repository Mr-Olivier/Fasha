import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/audit_log_entry.dart';
import 'admin_audit_api.dart';

class AdminAuditRepository {
  const AdminAuditRepository(this._api);

  final AdminAuditApi _api;

  Future<List<AuditLogEntry>> list({int limit = 50}) async {
    try {
      return await _api.list(limit: limit);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
