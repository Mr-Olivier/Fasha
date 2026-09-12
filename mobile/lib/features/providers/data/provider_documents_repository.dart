import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/provider_documents.dart';
import 'provider_documents_api.dart';

class ProviderDocumentsRepository {
  const ProviderDocumentsRepository(this._api);

  final ProviderDocumentsApi _api;

  Future<ProviderDocuments> getMyDocuments() => _guard(_api.getMyDocuments);

  Future<ProviderDocuments> uploadId(XFile image) => _guard(() => _api.uploadId(image));

  Future<ProviderDocuments> uploadTradeCertificate(XFile image) => _guard(() => _api.uploadTradeCertificate(image));

  Future<ProviderDocuments> uploadSelfie(XFile image) => _guard(() => _api.uploadSelfie(image));

  Future<ProviderDocuments> submit() => _guard(_api.submit);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
