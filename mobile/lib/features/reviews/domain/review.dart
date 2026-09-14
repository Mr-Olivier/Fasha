import 'review_tag.dart';

/// Mirrors the backend's ReviewResponse DTO.
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    this.tags = const {},
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final int rating;
  final String? comment;
  final Set<ReviewTag> tags;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => ReviewTagJson.fromWire(e as String)).toSet(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
