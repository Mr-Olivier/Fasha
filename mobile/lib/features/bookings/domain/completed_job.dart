/// Mirrors the backend's CompletedJobResponse DTO - one row on D8's
/// completed-jobs list.
class CompletedJob {
  const CompletedJob({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.serviceName,
    required this.price,
    required this.completedAt,
    this.rating,
    this.reviewComment,
    required this.hasReview,
  });

  final String bookingId;
  final String customerId;
  final String customerName;
  final String serviceName;
  final double price;
  final DateTime completedAt;
  final int? rating;
  final String? reviewComment;
  final bool hasReview;

  factory CompletedJob.fromJson(Map<String, dynamic> json) => CompletedJob(
        bookingId: json['bookingId'] as String,
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        serviceName: json['serviceName'] as String,
        price: (json['price'] as num).toDouble(),
        completedAt: DateTime.parse(json['completedAt'] as String),
        rating: (json['rating'] as num?)?.toInt(),
        reviewComment: json['reviewComment'] as String?,
        hasReview: json['hasReview'] as bool,
      );
}
