import 'package:dio/dio.dart';

import '../domain/audit_log_entry.dart';

/// Raw HTTP call to GET /api/admin/audit-log - admin-only, enforced
/// server-side by @PreAuthorize("hasRole('ADMIN')") on AdminAuditController.
class AdminAuditApi {
  const AdminAuditApi(this._dio);

  final Dio _dio;

  Future<List<AuditLogEntry>> list({int limit = 50}) async {
    final response = await _dio.get<List<dynamic>>('/admin/audit-log', queryParameters: {'limit': limit});
    return response.data!.map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
