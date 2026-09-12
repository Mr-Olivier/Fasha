import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/booking_photo_api.dart';
import '../data/booking_photo_repository.dart';
import '../domain/booking_photo.dart';

final bookingPhotoApiProvider = Provider<BookingPhotoApi>(
  (ref) => BookingPhotoApi(ref.watch(apiClientProvider).dio),
);

final bookingPhotoRepositoryProvider = Provider<BookingPhotoRepository>(
  (ref) => BookingPhotoRepository(ref.watch(bookingPhotoApiProvider)),
);

/// One booking's photos - keyed by booking id since both D2 (a customer's
/// upload, read-only from the provider's side) and D3 (the provider's own
/// uploads) show this same list for whichever booking is open.
class BookingPhotoController extends FamilyAsyncNotifier<List<BookingPhoto>, String> {
  @override
  Future<List<BookingPhoto>> build(String bookingId) {
    return ref.read(bookingPhotoRepositoryProvider).list(bookingId);
  }

  Future<void> upload(XFile image) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(bookingPhotoRepositoryProvider);
      await repository.upload(arg, image);
      return repository.list(arg);
    });
  }
}

final bookingPhotoControllerProvider =
    AsyncNotifierProvider.family<BookingPhotoController, List<BookingPhoto>, String>(BookingPhotoController.new);
