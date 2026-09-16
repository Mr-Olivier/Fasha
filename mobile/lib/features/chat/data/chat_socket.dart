import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

/// Live delivery for one booking's chat - connects to ChatWebSocketHandler
/// on the backend, replacing ChatScreen's old 4-second poll
/// (Timer.periodic) with real-time push. Sending a message still goes
/// through the normal REST endpoint (ChatApi.sendMessage); this class
/// handles the two things that flow the other way while this screen is
/// open: the other party's messages, and their "typing..." presence.
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
    _channel.stream.listen(_onFrame, onError: (Object _) {});
  }

  late final WebSocketChannel _channel;
  final _messages = StreamController<ChatMessage>.broadcast();
  final _typing = StreamController<String>.broadcast();
  final _cleared = StreamController<void>.broadcast();

  /// One event per message the server broadcasts for this booking.
  Stream<ChatMessage> get messages => _messages.stream;

  /// One event per "the other party is typing" signal, carrying their
  /// user id (ChatScreen only ever has one other party per booking, but
  /// the id is there in case that ever changes). ChatWebSocketHandler
  /// never echoes this back to whoever sent it, so every event here is
  /// genuinely someone ELSE typing - never this device's own.
  Stream<String> get typingUserIds => _typing.stream;

  /// Fires when EITHER party clears this chat (see
  /// ChatWebSocketHandler.broadcastCleared) while this screen is open -
  /// ChatScreen re-fetches on this, same as a new message arriving, so an
  /// open conversation empties out live instead of only on next open.
  Stream<void> get cleared => _cleared.stream;

  /// Fire on every keystroke - ChatScreen debounces so this isn't sent more
  /// than once every couple of seconds while someone's actively typing.
  /// The literal string "typing", not JSON: see
  /// ChatWebSocketHandler.handleTextMessage's doc comment for why a whole
  /// envelope would be more machinery than this one signal warrants.
  void sendTyping() {
    if (_channel.closeCode == null) {
      _channel.sink.add('typing');
    }
  }

  /// Anything that isn't valid JSON, or doesn't match either shape this
  /// socket expects, is silently dropped rather than crashing the stream -
  /// a live update is a nice-to-have layered on top of the REST list,
  /// never the only way to see a message.
  void _onFrame(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      if (json['type'] == 'typing') {
        final senderId = json['senderId'] as String?;
        if (senderId != null) _typing.add(senderId);
        return;
      }
      if (json['type'] == 'cleared') {
        _cleared.add(null);
        return;
      }
      _messages.add(ChatMessage.fromJson(json));
    } catch (_) {
      // Malformed/unexpected frame - ignore, per this method's doc comment.
    }
  }

  void dispose() {
    _channel.sink.close();
    unawaited(_messages.close());
    unawaited(_typing.close());
    unawaited(_cleared.close());
  }
}
