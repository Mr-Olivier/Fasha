/// What kind of file a ChatMessage's attachment is - mirrors the backend's
/// MessageAttachmentType. Drives whether ChatScreen renders an inline photo
/// or a video thumbnail with a play button.
enum ChatAttachmentType {
  image,
  video;

  static ChatAttachmentType? fromWire(String? value) => switch (value) {
        'IMAGE' => ChatAttachmentType.image,
        'VIDEO' => ChatAttachmentType.video,
        _ => null,
      };
}

/// Mirrors the backend's MessageResponse DTO. senderName is shown above a
/// bubble; the screen compares senderId to the logged-in user's own id
/// (see AuthUser.userId) to decide which side of the thread it lands on.
/// [read] only matters for a bubble the logged-in user sent themselves -
/// it flips to true once the other party has opened this conversation,
/// which is what powers the ✓✓ read receipt.
///
/// [body] is null for an attachment-only message (a photo/video sent with
/// no caption); a message always has at least one of [body]/[attachmentType],
/// never neither - see the backend's own CHECK constraint. When
/// [attachmentType] is non-null, the actual file is fetched from
/// GET /bookings/{bookingId}/messages/{id}/attachment (see
/// ChatAttachmentImage/ChatAttachmentVideo) rather than embedded here.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.attachmentType,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String? body;
  final ChatAttachmentType? attachmentType;
  final DateTime createdAt;
  final bool read;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        body: json['body'] as String?,
        attachmentType: ChatAttachmentType.fromWire(json['attachmentType'] as String?),
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool,
      );
}
