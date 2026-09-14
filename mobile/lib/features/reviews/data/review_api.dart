import 'package:dio/dio.dart';

import '../domain/review.dart';
import '../domain/review_tag.dart';

/// Raw HTTP calls to POST /api/bookings/{bookingId}/reviews and
/// GET /api/providers/{providerId}/reviews.
class ReviewApi {
  const ReviewApi(this._dio);

  final Dio _dio;

  Future<Review> createReview({
    required String bookingId,
    required int rating,
    String? comment,
    Set<ReviewTag> tags = const {},
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bookings/$bookingId/reviews',
      data: {'rating': rating, 'comment': comment, 'tags': tags.map((t) => t.toWire()).toList()},
    );
    return Review.fromJson(response.data!);
  }

  Future<List<Review>> getReviewsForProvider(String providerId) async {
    final response = await _dio.get<List<dynamic>>('/providers/$providerId/reviews');
    return response.data!.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }
}
