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
class MyBookingsController extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() {
    return ref.read(bookingRepositoryProvider).listForCustomer();
  }

  Future<void> requestBooking({required String serviceListingId, String? note, DateTime? requestedDate}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.create(serviceListingId: serviceListingId, note: note, requestedDate: requestedDate);
      return repository.listForCustomer();
    });
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
