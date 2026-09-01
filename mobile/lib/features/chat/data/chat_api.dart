import 'package:dio/dio.dart';

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
}
