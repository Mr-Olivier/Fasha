import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/provider_documents.dart';

/// Raw HTTP calls to /api/providers/me/documents* (D7 "Get verified").
class ProviderDocumentsApi {
  const ProviderDocumentsApi(this._dio);

  final Dio _dio;

  Future<ProviderDocuments> getMyDocuments() async {
    final response = await _dio.get<Map<String, dynamic>>('/providers/me/documents');
    return ProviderDocuments.fromJson(response.data!);
  }

  Future<ProviderDocuments> uploadId(XFile image) => _upload('/providers/me/documents/id', image);

  Future<ProviderDocuments> uploadTradeCertificate(XFile image) =>
      _upload('/providers/me/documents/trade-certificate', image);

  Future<ProviderDocuments> uploadSelfie(XFile image) => _upload('/providers/me/documents/selfie', image);

  Future<ProviderDocuments> submit() async {
    final response = await _dio.post<Map<String, dynamic>>('/providers/me/documents/submit');
    return ProviderDocuments.fromJson(response.data!);
  }

  Future<ProviderDocuments> _upload(String path, XFile image) async {
    final bytes = await image.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: image.name),
    });
    final response = await _dio.post<Map<String, dynamic>>(path, data: formData);
    return ProviderDocuments.fromJson(response.data!);
  }
}
