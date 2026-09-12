/// Who sent a VerificationMessage - mirrors the backend's reuse of the
/// Role enum for provider_verification_messages.sender_role (always
/// PROVIDER or ADMIN in practice).
enum VerificationMessageSenderRole { provider, admin }

extension VerificationMessageSenderRoleJson on VerificationMessageSenderRole {
  static VerificationMessageSenderRole fromWire(String value) =>
      value == 'ADMIN' ? VerificationMessageSenderRole.admin : VerificationMessageSenderRole.provider;
}

/// Mirrors the backend's VerificationMessageResponse DTO - one message in
/// the two-way conversation between a provider and admin about their
/// verification (D7).
class VerificationMessage {
  const VerificationMessage({
    required this.id,
    required this.providerProfileId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String providerProfileId;
  final String senderId;
  final String senderName;
  final VerificationMessageSenderRole senderRole;
  final String body;
  final DateTime createdAt;

  factory VerificationMessage.fromJson(Map<String, dynamic> json) => VerificationMessage(
        id: json['id'] as String,
        providerProfileId: json['providerProfileId'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        senderRole: VerificationMessageSenderRoleJson.fromWire(json['senderRole'] as String),
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
