import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/review.dart';
import '../domain/review_tag.dart';
import 'review_api.dart';

class ReviewRepository {
  const ReviewRepository(this._api);

  final ReviewApi _api;

  Future<Review> createReview({
    required String bookingId,
    required int rating,
    String? comment,
    Set<ReviewTag> tags = const {},
  }) async {
    try {
      return await _api.createReview(bookingId: bookingId, rating: rating, comment: comment, tags: tags);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Review>> getReviewsForProvider(String providerId) async {
    try {
      return await _api.getReviewsForProvider(providerId);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
