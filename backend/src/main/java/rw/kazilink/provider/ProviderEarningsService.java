package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.booking.BookingStatus;
import rw.kazilink.review.Review;
import rw.kazilink.review.ReviewRepository;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Backs D8 ("Completed jobs & earnings") - every COMPLETED booking for the
 * caller's own provider profile, with its review (if any) attached. A
 * COMPLETED booking is terminal (see BookingStatus's state diagram) and
 * never updates again, so updatedAt doubles as "completedAt" without
 * needing a dedicated column.
 */
@Service
@RequiredArgsConstructor
public class ProviderEarningsService {

    private final ProviderProfileRepository providerProfileRepository;
    private final BookingRepository bookingRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final ServiceListingRepository serviceListingRepository;

    public EarningsSummaryResponse getSummary(UUID userId, String period) {
        var completed = completedBookings(userId, period);
        BigDecimal total = completed.stream().map(Booking::getPrice).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new EarningsSummaryResponse(total, completed.size(), "month".equals(period) ? "this month" : "all time");
    }

    public List<CompletedJobResponse> listCompletedJobs(UUID userId, String period) {
        var completed = completedBookings(userId, period);
        if (completed.isEmpty()) return List.of();

        Map<UUID, Review> reviewsByBookingId = reviewRepository
                .findByProviderProfileIdOrderByCreatedAtDesc(resolveProviderProfileId(userId)).stream()
                .collect(Collectors.toMap(Review::getBookingId, Function.identity()));

        return completed.stream().map(booking -> {
            User customer = userRepository.findById(booking.getCustomerId()).orElse(null);
            String serviceName = serviceListingRepository.findById(booking.getServiceListingId())
                    .map(ServiceListing::getName)
                    .orElse("Service");
            Review review = reviewsByBookingId.get(booking.getId());

            return new CompletedJobResponse(
                    booking.getId(),
                    booking.getCustomerId(),
                    customer != null ? customer.getName() : "Customer",
                    serviceName,
                    booking.getPrice(),
                    booking.getUpdatedAt(),
                    review != null ? review.getRating() : null,
                    review != null ? review.getComment() : null,
                    review != null
            );
        }).toList();
    }

    private List<Booking> completedBookings(UUID userId, String period) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        var completed = bookingRepository.findByProviderProfileIdAndStatusOrderByUpdatedAtDesc(
                providerProfileId, BookingStatus.COMPLETED);
        if (!"month".equals(period)) return completed;

        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        return completed.stream()
                .filter(booking -> {
                    LocalDate completedDate = booking.getUpdatedAt().atZone(ZoneOffset.UTC).toLocalDate();
                    return completedDate.getYear() == today.getYear() && completedDate.getMonth() == today.getMonth();
                })
                .toList();
    }

    private UUID resolveProviderProfileId(UUID userId) {
        return providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new)
                .getId();
    }
}
