package rw.kazilink.review;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingNotFoundException;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.booking.BookingStatus;
import rw.kazilink.booking.BookingStatusHistoryRepository;
import rw.kazilink.common.RateLimiter;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReviewServiceTest {

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BookingStatusHistoryRepository statusHistoryRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private NotificationService notificationService;

    @Mock
    private RateLimiter rateLimiter;

    @InjectMocks
    private ReviewService reviewService;

    private final UUID customerId = UUID.randomUUID();
    private final UUID providerProfileId = UUID.randomUUID();
    private final UUID bookingId = UUID.randomUUID();

    @Test
    void createReview_rejectsABookingThatIsNotCompletedYet() {
        Booking booking = new Booking(customerId, providerProfileId, UUID.randomUUID(), null, null, null, null);
        booking.setStatus(BookingStatus.ACCEPTED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> reviewService.createReview(customerId, bookingId, new CreateReviewRequest(5, "Great!", null)))
                .isInstanceOf(ReviewNotAllowedException.class);
    }

    @Test
    void createReview_rejectsABookingThatDoesNotBelongToTheCaller() {
        Booking booking = new Booking(UUID.randomUUID(), providerProfileId, UUID.randomUUID(), null, null, null, null);
        booking.setStatus(BookingStatus.COMPLETED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> reviewService.createReview(customerId, bookingId, new CreateReviewRequest(5, "Great!", null)))
                .isInstanceOf(BookingNotFoundException.class);
    }

    @Test
    void createReview_rejectsABookingThatWasAlreadyReviewed() {
        Booking booking = new Booking(customerId, providerProfileId, UUID.randomUUID(), null, null, null, null);
        booking.setStatus(BookingStatus.COMPLETED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(true);

        assertThatThrownBy(() -> reviewService.createReview(customerId, bookingId, new CreateReviewRequest(5, "Great!", null)))
                .isInstanceOf(ReviewNotAllowedException.class);
    }

    @Test
    void createReview_savesTheReviewAndMarksTheBookingReviewed() {
        Booking booking = new Booking(customerId, providerProfileId, UUID.randomUUID(), null, null, null, null);
        booking.setStatus(BookingStatus.COMPLETED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);

        User customer = new User("Alice Uwase", "alice@example.com", null, "hash", Role.CUSTOMER);
        when(userRepository.findById(customerId)).thenReturn(Optional.of(customer));
        ProviderProfile provider = new ProviderProfile(UUID.randomUUID(), "JP Electrical", null, null, null);
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(provider));

        ReviewResponse response = reviewService.createReview(customerId, bookingId, new CreateReviewRequest(4, "Good work", null));

        assertThat(response.rating()).isEqualTo(4);
        assertThat(response.comment()).isEqualTo("Good work");
        assertThat(response.customerName()).isEqualTo("Alice Uwase");
        assertThat(booking.getStatus()).isEqualTo(BookingStatus.REVIEWED);
    }

    @Test
    void getReviewsForProvider_returnsThemMostRecentFirst() {
        User customer = new User("Alice Uwase", "alice@example.com", null, "hash", Role.CUSTOMER);
        when(userRepository.findById(customerId)).thenReturn(Optional.of(customer));
        Review review = new Review(bookingId, customerId, providerProfileId, 5, "Excellent", null);
        when(reviewRepository.findByProviderProfileIdOrderByCreatedAtDesc(providerProfileId)).thenReturn(List.of(review));

        List<ReviewResponse> responses = reviewService.getReviewsForProvider(providerProfileId);

        assertThat(responses).hasSize(1);
        assertThat(responses.get(0).rating()).isEqualTo(5);
    }
}
