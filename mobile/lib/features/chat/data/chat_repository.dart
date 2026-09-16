import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../domain/chat_message.dart';
import 'chat_api.dart';

class ChatRepository {
  const ChatRepository(this._api);

  final ChatApi _api;

  Future<List<ChatMessage>> listMessages(String bookingId) async {
    try {
      return await _api.listMessages(bookingId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ChatMessage> sendMessage({required String bookingId, required String body}) async {
    try {
      return await _api.sendMessage(bookingId: bookingId, body: body);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ChatMessage> sendAttachment({required String bookingId, required XFile file, String? caption}) async {
    try {
      return await _api.sendAttachment(bookingId: bookingId, file: file, caption: caption);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> clearChat(String bookingId) async {
    try {
      await _api.clearChat(bookingId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
