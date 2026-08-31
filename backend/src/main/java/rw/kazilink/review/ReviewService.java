package rw.kazilink.review;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingNotFoundException;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.booking.BookingStatus;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;

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
    private final UserRepository userRepository;

    @Transactional
    public ReviewResponse createReview(UUID customerId, UUID bookingId, CreateReviewRequest request) {
        Booking booking = bookingRepository.findById(bookingId)
                .filter(b -> b.getCustomerId().equals(customerId))
                .orElseThrow(BookingNotFoundException::new);

        if (booking.getStatus() != BookingStatus.COMPLETED) {
            throw new ReviewNotAllowedException("Only a completed booking can be reviewed.");
        }
        if (reviewRepository.existsByBookingId(bookingId)) {
            throw new ReviewNotAllowedException("This booking has already been reviewed.");
        }

        Review review = new Review(bookingId, customerId, booking.getProviderProfileId(), request.rating(), request.comment());
        reviewRepository.save(review);

        // The review IS the "mark this reviewed" action - see BookingStatus's doc comment for why there's no separate endpoint.
        booking.setStatus(BookingStatus.REVIEWED);
        bookingRepository.save(booking);

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
                review.getCreatedAt()
        );
    }
}
