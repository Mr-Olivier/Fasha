import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/booking_api.dart';
import '../data/booking_repository.dart';
import '../domain/booking.dart';

final bookingApiProvider = Provider<BookingApi>(
  (ref) => BookingApi(ref.watch(apiClientProvider).dio),
);

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(ref.watch(bookingApiProvider)),
);

/// A customer's own bookings. Same "mutate then re-fetch the whole list"
/// shape as ServiceListingController - simpler to reason about than
/// patching one item in place, and the list is small enough that
/// re-fetching costs nothing noticeable.
///
/// Deliberately has NO "create/request a booking" method - see
/// RequestBookingController below for why that needs to be a separate,
/// dedicated controller rather than living here.
class MyBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() {
    return ref.read(bookingRepositoryProvider).listForCustomer();
  }

  /// Only actually succeeds server-side while the booking is still
  /// REQUESTED or ACCEPTED - see BookingService.cancel on the backend.
  Future<void> cancel(String bookingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.cancel(bookingId);
      return repository.listForCustomer();
    });
  }
}

final myBookingsControllerProvider = AsyncNotifierProvider<MyBookingsController, List<Booking>>(MyBookingsController.new);

/// Submitting a new booking request (RequestBookingScreen) - deliberately
/// its OWN controller rather than a method on MyBookingsController.
///
/// MyBookingsController's state doubles as "is the bookings list loading"
/// AND would otherwise double as "is my submission loading" - the same
/// screen watching both meanings on one shared provider can't tell "the
/// list's own background fetch just finished" apart from "my submit just
/// succeeded". That's not hypothetical: it briefly caused
/// RequestBookingScreen to auto-navigate away the instant its own
/// nothing-to-do-with-submitting list fetch resolved. A dedicated
/// true-once-on-success bool (same shape as auth's ResetPasswordController)
/// has no such ambiguity.
class RequestBookingController extends AsyncNotifier<bool> {
  /// The booking `submit` just created - NOT Riverpod state (nothing
  /// should rebuild off it), just a place RequestBookingScreen can read
  /// the new id from right after a successful submit, to attach any
  /// photos the customer picked (see D2's "Photos from customer").
  String? lastCreatedBookingId;

  @override
  Future<bool> build() async => false;

  Future<void> submit({required String serviceListingId, String? note, DateTime? requestedDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .create(serviceListingId: serviceListingId, note: note, requestedDate: requestedDate);
      lastCreatedBookingId = booking.id;
      // So "My Bookings" shows the new request next time it's opened,
      // without this controller needing to know anything about that one's
      // internal state.
      ref.invalidate(myBookingsControllerProvider);
      return true;
    });
  }
}

final requestBookingControllerProvider =
    AsyncNotifierProvider<RequestBookingController, bool>(RequestBookingController.new);

/// A provider's incoming requests - the other side of the same bookings,
/// with the provider-only actions (accept/reject/start/complete) instead
/// of create/cancel.
class IncomingRequestsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() {
    return ref.read(bookingRepositoryProvider).listForProvider();
  }

  Future<void> accept(String bookingId) => _mutate((repository) => repository.accept(bookingId));

  Future<void> reject(String bookingId) => _mutate((repository) => repository.reject(bookingId));

  Future<void> start(String bookingId) => _mutate((repository) => repository.start(bookingId));

  Future<void> complete(String bookingId) => _mutate((repository) => repository.complete(bookingId));

  Future<void> updateWorkNote(String bookingId, String? note) =>
      _mutate((repository) => repository.updateWorkNote(bookingId, note));

  Future<void> _mutate(Future<Booking> Function(BookingRepository repository) action) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingRepositoryProvider);
      await action(repository);
      return repository.listForProvider();
    });
  }
}

final incomingRequestsControllerProvider =
    AsyncNotifierProvider<IncomingRequestsController, List<Booking>>(IncomingRequestsController.new);
