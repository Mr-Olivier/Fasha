/// Mirrors the backend's ReviewResponse DTO.
class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
