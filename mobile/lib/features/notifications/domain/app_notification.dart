/// Mirrors the backend's NotificationResponse. Named AppNotification (not
/// just Notification) to avoid colliding with Flutter's own
/// dart:ui/material Notification class.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.bookingId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String? bookingId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        bookingId: json['bookingId'] as String?,
        read: json['read'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
