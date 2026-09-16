import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/chat_message.dart';

class ChatApi {
  const ChatApi(this._dio);

  final Dio _dio;

  Future<List<ChatMessage>> listMessages(String bookingId) async {
    final response = await _dio.get<List<dynamic>>('/bookings/$bookingId/messages');
    return response.data!.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage({required String bookingId, required String body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/messages',
      data: {'body': body},
    );
    return ChatMessage.fromJson(response.data!);
  }

  /// [file] is a photo or short video picked/recorded on-device; [caption]
  /// is the optional text alongside it, same as [sendMessage]'s body but on
  /// a multipart request instead of JSON, since a plain JSON body can't
  /// carry a file. Content-type is inferred server-side from [file]'s own
  /// filename extension - same convention BookingPhotoApi.upload already
  /// relies on, not something this call needs to specify itself.
  Future<ChatMessage> sendAttachment({required String bookingId, required XFile file, String? caption}) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/messages/attachment',
      data: formData,
    );
    return ChatMessage.fromJson(response.data!);
  }

  /// "Clear chat" - permanently deletes every message and attachment in
  /// this conversation for both parties. See the backend's
  /// MessageService.clearChat doc comment for why this is a real delete,
  /// not a per-device hide.
  Future<void> clearChat(String bookingId) => _dio.delete<void>('/bookings/$bookingId/messages');
}
