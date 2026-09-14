package rw.kazilink.booking;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.common.RateLimiter;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingNotFoundException;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;

import java.time.Duration;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;

/**
 * All the business rules for the booking lifecycle (see BookingStatus's doc
 * comment for the state diagram). Every "act on a booking" method takes the
 * CALLER's own id and re-derives which booking they're even allowed to
 * touch - the booking id alone is never enough, so there's no way to accept
 * or cancel someone else's booking just by guessing its id.
 */
@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final BookingStatusHistoryRepository statusHistoryRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final RateLimiter rateLimiter;

    // A genuine customer requests a handful of jobs in a sitting at most -
    // this is abuse prevention (someone scripting POST /api/bookings to
    // spam providers with fake requests), not a real usage ceiling.
    private static final int MAX_BOOKINGS_PER_HOUR = 10;

    @Transactional
    public BookingResponse createBooking(UUID customerId, CreateBookingRequest request) {
        rateLimiter.checkAllowed("booking:" + customerId, MAX_BOOKINGS_PER_HOUR, Duration.ofHours(1));

        ServiceListing service = serviceListingRepository.findById(request.serviceListingId())
                .orElseThrow(ServiceListingNotFoundException::new);
        ProviderProfile provider = providerProfileRepository.findById(service.getProviderProfileId())
                .orElseThrow(ProviderProfileNotFoundException::new);
        User customer = userRepository.findById(customerId).orElseThrow(UserNotFoundException::new);

        Booking booking = new Booking(
                customerId,
                service.getProviderProfileId(),
                service.getId(),
                request.note(),
                request.requestedDate(),
                request.address(),
                request.timeWindow(),
                service.getPrice());
        bookingRepository.save(booking);
        recordStatus(booking);

        notificationService.create(
                provider.getUserId(),
                "New booking request",
                customer.getName() + " requested " + service.getName(),
                booking.getId());

        return toResponse(booking);
    }

    public List<BookingResponse> listForCustomer(UUID customerId) {
        return bookingRepository.findByCustomerIdOrderByCreatedAtDesc(customerId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<BookingResponse> listForProvider(UUID userId) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        return bookingRepository.findByProviderProfileIdOrderByCreatedAtDesc(providerProfileId).stream()
                .map(this::toResponse)
                .toList();
    }

    public BookingResponse getForCustomer(UUID customerId, UUID bookingId) {
        return toResponse(findOwnedByCustomer(customerId, bookingId));
    }

    public BookingResponse getForProvider(UUID userId, UUID bookingId) {
        return toResponse(findOwnedByProvider(userId, bookingId));
    }

    @Transactional
    public BookingResponse accept(UUID userId, UUID bookingId) {
        Booking booking = findOwnedByProvider(userId, bookingId);
        requireStatus(booking, BookingStatus.REQUESTED);
        booking.setStatus(BookingStatus.ACCEPTED);
        bookingRepository.save(booking);
        recordStatus(booking);
        notifyCustomer(booking, "Request accepted", providerName -> providerName + " accepted your request");
        return toResponse(booking);
    }

    @Transactional
    public BookingResponse reject(UUID userId, UUID bookingId) {
        Booking booking = findOwnedByProvider(userId, bookingId);
        requireStatus(booking, BookingStatus.REQUESTED);
        booking.setStatus(BookingStatus.REJECTED);
        bookingRepository.save(booking);
        recordStatus(booking);
        notifyCustomer(booking, "Request declined", providerName -> providerName + " can't take this request right now");
        return toResponse(booking);
    }

    @Transactional
    public BookingResponse start(UUID userId, UUID bookingId) {
        Booking booking = findOwnedByProvider(userId, bookingId);
        requireStatus(booking, BookingStatus.ACCEPTED);
        booking.setStatus(BookingStatus.IN_PROGRESS);
        bookingRepository.save(booking);
        recordStatus(booking);
        notifyCustomer(booking, "Job started", providerName -> providerName + " has started working on your job");
        return toResponse(booking);
    }

    @Transactional
    public BookingResponse complete(UUID userId, UUID bookingId) {
        Booking booking = findOwnedByProvider(userId, bookingId);
        requireStatus(booking, BookingStatus.IN_PROGRESS);
        booking.setStatus(BookingStatus.COMPLETED);
        bookingRepository.save(booking);
        recordStatus(booking);
        notifyCustomer(booking, "Job completed", providerName -> "Your job with " + providerName + " is complete - leave a review");
        return toResponse(booking);
    }

    /** The note a provider leaves for the customer while a job is under way - only while IN_PROGRESS, same as starting/completing it. */
    @Transactional
    public BookingResponse updateWorkNote(UUID userId, UUID bookingId, String note) {
        Booking booking = findOwnedByProvider(userId, bookingId);
        requireStatus(booking, BookingStatus.IN_PROGRESS);
        booking.setWorkNote(note);
        bookingRepository.save(booking);
        return toResponse(booking);
    }

    /** A customer can only back out before the job is actually under way - not once it's IN_PROGRESS or later. */
    @Transactional
    public BookingResponse cancel(UUID customerId, UUID bookingId, String reason) {
        Booking booking = findOwnedByCustomer(customerId, bookingId);
        if (booking.getStatus() != BookingStatus.REQUESTED && booking.getStatus() != BookingStatus.ACCEPTED) {
            throw new InvalidBookingTransitionException(
                    "A booking that's " + booking.getStatus() + " can no longer be cancelled.");
        }
        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancellationReason(reason);
        bookingRepository.save(booking);
        recordStatus(booking);

        User customer = userRepository.findById(customerId).orElseThrow(UserNotFoundException::new);
        ProviderProfile provider = providerProfileRepository.findById(booking.getProviderProfileId())
                .orElseThrow(ProviderProfileNotFoundException::new);
        notificationService.create(
                provider.getUserId(),
                "Booking cancelled",
                customer.getName() + " cancelled their request",
                booking.getId());

        return toResponse(booking);
    }

    /** Appends one row to booking_status_history - called right after every status change is saved. */
    private void recordStatus(Booking booking) {
        statusHistoryRepository.save(new BookingStatusHistory(booking.getId(), booking.getStatus()));
    }

    /** Shared by accept/reject/start/complete - each just supplies its own wording around the provider's business name. */
    private void notifyCustomer(Booking booking, String title, Function<String, String> bodyBuilder) {
        ProviderProfile provider = providerProfileRepository.findById(booking.getProviderProfileId())
                .orElseThrow(ProviderProfileNotFoundException::new);
        notificationService.create(booking.getCustomerId(), title, bodyBuilder.apply(provider.getBusinessName()), booking.getId());
    }

    private void requireStatus(Booking booking, BookingStatus expected) {
        if (booking.getStatus() != expected) {
            throw new InvalidBookingTransitionException(
                    "This booking is " + booking.getStatus() + ", not " + expected + " - that action doesn't apply here.");
        }
    }

    private Booking findOwnedByCustomer(UUID customerId, UUID bookingId) {
        return bookingRepository.findById(bookingId)
                .filter(booking -> booking.getCustomerId().equals(customerId))
                .orElseThrow(BookingNotFoundException::new);
    }

    private Booking findOwnedByProvider(UUID userId, UUID bookingId) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        return bookingRepository.findById(bookingId)
                .filter(booking -> booking.getProviderProfileId().equals(providerProfileId))
                .orElseThrow(BookingNotFoundException::new);
    }

    private UUID resolveProviderProfileId(UUID userId) {
        return providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new)
                .getId();
    }

    private BookingResponse toResponse(Booking booking) {
        User customer = userRepository.findById(booking.getCustomerId()).orElseThrow(UserNotFoundException::new);
        ProviderProfile provider = providerProfileRepository.findById(booking.getProviderProfileId())
                .orElseThrow(ProviderProfileNotFoundException::new);
        User providerOwner = userRepository.findById(provider.getUserId()).orElseThrow(UserNotFoundException::new);
        ServiceListing service = serviceListingRepository.findById(booking.getServiceListingId())
                .orElseThrow(ServiceListingNotFoundException::new);
        List<BookingStatusHistoryEntry> history = statusHistoryRepository
                .findByBookingIdOrderByChangedAtAsc(booking.getId()).stream()
                .map(entry -> new BookingStatusHistoryEntry(entry.getStatus(), entry.getChangedAt()))
                .toList();

        return new BookingResponse(
                booking.getId(),
                booking.getCustomerId(),
                customer.getName(),
                customer.getPhone(),
                booking.getProviderProfileId(),
                provider.getBusinessName(),
                providerOwner.getPhone(),
                booking.getServiceListingId(),
                service.getName(),
                booking.getPrice(),
                booking.getNote(),
                booking.getRequestedDate(),
                booking.getAddress(),
                booking.getTimeWindow(),
                booking.getStatus(),
                booking.getWorkNote(),
                booking.getCancellationReason(),
                history,
                booking.getCreatedAt(),
                booking.getUpdatedAt()
        );
    }
}
