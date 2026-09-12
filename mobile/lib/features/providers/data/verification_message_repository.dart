import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/verification_message.dart';
import 'verification_message_api.dart';

class VerificationMessageRepository {
  const VerificationMessageRepository(this._api);

  final VerificationMessageApi _api;

  Future<List<VerificationMessage>> listMine() => _guard(_api.listMine);

  Future<VerificationMessage> sendMine(String body) => _guard(() => _api.sendMine(body));

  Future<List<VerificationMessage>> listForProvider(String providerProfileId) =>
      _guard(() => _api.listForProvider(providerProfileId));

  Future<VerificationMessage> sendAsAdmin({required String providerProfileId, required String body}) =>
      _guard(() => _api.sendAsAdmin(providerProfileId: providerProfileId, body: body));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
