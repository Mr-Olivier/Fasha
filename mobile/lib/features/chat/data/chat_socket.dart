import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

/// Live delivery for one booking's chat - connects to ChatWebSocketHandler
/// on the backend, replacing ChatScreen's old 4-second poll
/// (Timer.periodic) with real-time push. Sending a message still goes
/// through the normal REST endpoint (ChatApi.sendMessage); this class only
/// receives what the OTHER party sends while this screen is open.
///
/// The access token travels as a query parameter, not a header - browsers'
/// native WebSocket API can't set custom headers on the handshake at all
/// (see ChatWebSocketHandler's doc comment on the backend for the same
/// constraint). No reconnect-on-drop logic here: a dropped connection just
/// means live updates pause until the screen is reopened, same as before
/// this feature existed - the REST list is still the source of truth.
class ChatSocket {
  ChatSocket({required String bookingId, required String token}) {
    final uri = Uri.parse('${ApiClient.wsBaseUrl}/ws/chat').replace(
      queryParameters: {'bookingId': bookingId, 'token': token},
    );
    _channel = WebSocketChannel.connect(uri);
  }

  late final WebSocketChannel _channel;

  /// One event per message the server broadcasts for this booking.
  /// Anything that isn't valid JSON in the expected shape is silently
  /// dropped rather than crashing the stream - a live update is a
  /// nice-to-have layered on top of the REST list, never the only way to
  /// see a message.
  Stream<ChatMessage> get messages => _channel.stream
      .map((raw) => ChatMessage.fromJson(jsonDecode(raw as String) as Map<String, dynamic>))
      .handleError((Object _) {});

  void dispose() {
    _channel.sink.close();
  }
}
