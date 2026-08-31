import 'package:dio/dio.dart';

import '../../providers/domain/verification_status.dart';
import '../domain/pending_provider.dart';

/// Raw HTTP calls to GET/PATCH /api/admin/providers - admin-only, enforced
/// server-side by @PreAuthorize("hasRole('ADMIN')") on AdminProviderController.
class AdminProviderApi {
  const AdminProviderApi(this._dio);

  final Dio _dio;

  Future<List<PendingProvider>> listProviders({VerificationStatus? status}) async {
    final response = await _dio.get<List<dynamic>>(
      '/admin/providers',
      queryParameters: status != null ? {'status': status.toWire()} : null,
    );
    return response.data!.map((e) => PendingProvider.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PendingProvider> decide({required String providerId, required bool approved}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/providers/$providerId/approve',
      data: {'approved': approved},
    );
    return PendingProvider.fromJson(response.data!);
  }
}
