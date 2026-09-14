package rw.kazilink.review;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingNotFoundException;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.booking.BookingStatus;
import rw.kazilink.booking.BookingStatusHistory;
import rw.kazilink.booking.BookingStatusHistoryRepository;
import rw.kazilink.common.RateLimiter;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;

import java.time.Duration;
import java.util.List;
import java.util.UUID;

/**
 * Business rules for leaving a review - only the customer who made the
 * booking can review it, only once it's COMPLETED, and only once ever
 * (see the "reviews.booking_id" unique constraint this double-checks
 * before the database would reject it with a raw SQL error).
 */
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final BookingStatusHistoryRepository statusHistoryRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final RateLimiter rateLimiter;

    // Same reasoning as BookingService.MAX_BOOKINGS_PER_HOUR - a real
    // customer leaves at most a few reviews in one sitting; this exists to
    // blunt scripted abuse, not to cap normal use (each review is also
    // already gated to one per completed booking).
    private static final int MAX_REVIEWS_PER_HOUR = 10;

    @Transactional
    public ReviewResponse createReview(UUID customerId, UUID bookingId, CreateReviewRequest request) {
        rateLimiter.checkAllowed("review:" + customerId, MAX_REVIEWS_PER_HOUR, Duration.ofHours(1));

        Booking booking = bookingRepository.findById(bookingId)
                .filter(b -> b.getCustomerId().equals(customerId))
                .orElseThrow(BookingNotFoundException::new);

        if (booking.getStatus() != BookingStatus.COMPLETED) {
            throw new ReviewNotAllowedException("Only a completed booking can be reviewed.");
        }
        if (reviewRepository.existsByBookingId(bookingId)) {
            throw new ReviewNotAllowedException("This booking has already been reviewed.");
        }

        Review review = new Review(
                bookingId, customerId, booking.getProviderProfileId(), request.rating(), request.comment(), request.tags());
        reviewRepository.save(review);

        // The review IS the "mark this reviewed" action - see BookingStatus's doc comment for why there's no separate endpoint.
        booking.setStatus(BookingStatus.REVIEWED);
        bookingRepository.save(booking);
        statusHistoryRepository.save(new BookingStatusHistory(booking.getId(), BookingStatus.REVIEWED));

        User customer = userRepository.findById(customerId).orElseThrow(UserNotFoundException::new);
        ProviderProfile provider = providerProfileRepository.findById(booking.getProviderProfileId())
                .orElseThrow(ProviderProfileNotFoundException::new);
        notificationService.create(
                provider.getUserId(),
                "New review",
                customer.getName() + " left a " + request.rating() + "-star review",
                booking.getId());

        return toResponse(review);
    }

    public List<ReviewResponse> getReviewsForProvider(UUID providerProfileId) {
        return reviewRepository.findByProviderProfileIdOrderByCreatedAtDesc(providerProfileId).stream()
                .map(this::toResponse)
                .toList();
    }

    private ReviewResponse toResponse(Review review) {
        User customer = userRepository.findById(review.getCustomerId()).orElseThrow(UserNotFoundException::new);
        return new ReviewResponse(
                review.getId(),
                review.getBookingId(),
                review.getCustomerId(),
                customer.getName(),
                review.getRating(),
                review.getComment(),
                review.getTags(),
                review.getCreatedAt()
        );
    }
}
