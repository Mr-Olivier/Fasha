import 'package:dio/dio.dart';

import '../domain/verification_message.dart';

/// Raw HTTP calls for the D7 verification conversation - the provider side
/// always uses /me (it never needs its own providerProfileId just to open
/// this thread); admin always targets an explicit provider id, since one
/// admin account reads/replies to many providers' threads.
class VerificationMessageApi {
  const VerificationMessageApi(this._dio);

  final Dio _dio;

  Future<List<VerificationMessage>> listMine() async {
    final response = await _dio.get<List<dynamic>>('/providers/me/verification-messages');
    return response.data!.map((e) => VerificationMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VerificationMessage> sendMine(String body) async {
    final response = await _dio.post<Map<String, dynamic>>('/providers/me/verification-messages', data: {'body': body});
    return VerificationMessage.fromJson(response.data!);
  }

  Future<List<VerificationMessage>> listForProvider(String providerProfileId) async {
    final response = await _dio.get<List<dynamic>>('/providers/$providerProfileId/verification-messages');
    return response.data!.map((e) => VerificationMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<VerificationMessage> sendAsAdmin({required String providerProfileId, required String body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/providers/$providerProfileId/verification-messages',
      data: {'body': body},
    );
    return VerificationMessage.fromJson(response.data!);
  }
}
