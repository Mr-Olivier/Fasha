import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../providers/domain/verification_status.dart';
import '../domain/pending_provider.dart';
import 'admin_provider_api.dart';

class AdminProviderRepository {
  const AdminProviderRepository(this._api);

  final AdminProviderApi _api;

  Future<List<PendingProvider>> listProviders({VerificationStatus? status}) async {
    try {
      return await _api.listProviders(status: status);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<PendingProvider> decide({required String providerId, required bool approved}) async {
    try {
      return await _api.decide(providerId: providerId, approved: approved);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteDocument({required String providerId, required String documentType}) async {
    try {
      await _api.deleteDocument(providerId: providerId, documentType: documentType);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
