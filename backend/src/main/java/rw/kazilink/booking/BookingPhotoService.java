package rw.kazilink.booking;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import rw.kazilink.common.SecureFileStorageService;
import rw.kazilink.provider.ProviderProfileRepository;

import java.util.List;
import java.util.UUID;

/**
 * Photos attached to a booking - the customer's evidence of the problem
 * (D2) or the provider's proof of the finished work (D3). Both directions
 * share this one service: whichever party is calling, we work out which
 * role they're acting as from the booking itself rather than trusting a
 * client-supplied role param.
 *
 * Deliberately has NO admin-facing method at all - completion/request
 * photos are private between the booking's own two parties, the same
 * trust boundary as their per-booking chat (see PROJECT_STATUS.md's
 * provider-tools plan, decision #4).
 */
@Service
@RequiredArgsConstructor
public class BookingPhotoService {

    private final BookingRepository bookingRepository;
    private final BookingPhotoRepository bookingPhotoRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final SecureFileStorageService fileStorageService;

    @Transactional
    public BookingPhotoResponse upload(UUID userId, UUID bookingId, MultipartFile file) {
        Booking booking = findAccessible(userId, bookingId);
        PhotoUploaderRole role = roleOf(userId, booking);

        String storagePath = fileStorageService.store("booking-photos", bookingId.toString(), file);
        BookingPhoto photo = new BookingPhoto(bookingId, role, storagePath);
        bookingPhotoRepository.save(photo);
        return BookingPhotoResponse.from(photo);
    }

    public List<BookingPhotoResponse> list(UUID userId, UUID bookingId) {
        findAccessible(userId, bookingId);
        return bookingPhotoRepository.findByBookingIdOrderByCreatedAtAsc(bookingId).stream()
                .map(BookingPhotoResponse::from)
                .toList();
    }

    public Resource download(UUID userId, UUID bookingId, UUID photoId) {
        findAccessible(userId, bookingId);
        BookingPhoto photo = bookingPhotoRepository.findById(photoId)
                .filter(p -> p.getBookingId().equals(bookingId))
                .orElseThrow(BookingNotFoundException::new);
        return fileStorageService.load(photo.getStoragePath());
    }

    /** Either the booking's own customer or its own provider - anyone else gets the same "not found" a bad id would. */
    private Booking findAccessible(UUID userId, UUID bookingId) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(BookingNotFoundException::new);
        boolean isCustomer = booking.getCustomerId().equals(userId);
        boolean isProvider = providerProfileRepository.findByUserId(userId)
                .map(profile -> profile.getId().equals(booking.getProviderProfileId()))
                .orElse(false);
        if (!isCustomer && !isProvider) {
            throw new BookingNotFoundException();
        }
        return booking;
    }

    private PhotoUploaderRole roleOf(UUID userId, Booking booking) {
        return booking.getCustomerId().equals(userId) ? PhotoUploaderRole.CUSTOMER : PhotoUploaderRole.PROVIDER;
    }
}
