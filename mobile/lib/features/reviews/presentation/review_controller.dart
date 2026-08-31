import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../bookings/presentation/booking_controller.dart';
import '../data/review_api.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';

final reviewApiProvider = Provider<ReviewApi>(
  (ref) => ReviewApi(ref.watch(apiClientProvider).dio),
);

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(reviewApiProvider)),
);

/// A provider's reviews, shown on ProviderDetailScreen. Read-only from the
/// app's point of view (no edit/delete yet), so a plain FutureProvider.family
/// is enough - same reasoning as providerBrowseProvider.
final providerReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, providerId) => ref.watch(reviewRepositoryProvider).getReviewsForProvider(providerId),
);

/// Submitting a review for a COMPLETED booking - its own dedicated
/// controller (not a method on MyBookingsController), for the exact same
/// reason RequestBookingController is separate: MyBookingsController's
/// state doubles as "is the bookings list loading", which would make a
/// "did my submission succeed" check on that same provider ambiguous with
/// its own unrelated background list fetch. See RequestBookingController's
/// doc comment for the full story - this was a real bug there before it
/// got its own controller.
class SubmitReviewController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({required String bookingId, required int rating, String? comment}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(reviewRepositoryProvider).createReview(bookingId: bookingId, rating: rating, comment: comment);
      // So "My Bookings" shows the booking as REVIEWED next time it's viewed.
      ref.invalidate(myBookingsControllerProvider);
      return true;
    });
  }
}

final submitReviewControllerProvider =
    AsyncNotifierProvider<SubmitReviewController, bool>(SubmitReviewController.new);
