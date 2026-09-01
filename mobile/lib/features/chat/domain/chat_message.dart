/// Mirrors the backend's MessageResponse DTO. senderName is shown above a
/// bubble; the screen compares senderId to the logged-in user's own id
/// (see AuthUser.userId) to decide which side of the thread it lands on.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
