package rw.fasha.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import rw.fasha.booking.Booking;
import rw.fasha.booking.BookingRepository;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.provider.VerificationStatus;
import rw.fasha.user.Role;
import rw.fasha.user.User;
import rw.fasha.user.UserRepository;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminStatsService {

    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final BookingRepository bookingRepository;

    public AdminStatsResponse getStats() {
        long pendingApprovals = providerProfileRepository.countByVerificationStatus(VerificationStatus.PENDING);
        long activeProviders = providerProfileRepository.countByVerificationStatus(VerificationStatus.APPROVED);
        long totalCustomers = userRepository.countByRole(Role.CUSTOMER);
        long bookingsLast30Days = bookingRepository.countByCreatedAtAfter(Instant.now().minus(30, ChronoUnit.DAYS));

        return new AdminStatsResponse(pendingApprovals, activeProviders, totalCustomers, bookingsLast30Days);
    }

    /**
     * One point per calendar day (UTC) that had at least one booking over
     * the last `days` days - days with zero bookings simply don't appear,
     * which the chart renders as a gap rather than a zero. Bucketed here in
     * plain Java rather than a database GROUP BY: this MVP's booking volume
     * is small enough that pulling the raw rows and grouping them costs
     * nothing measurable, and it avoids a native, Postgres-specific date-
     * truncation query for what JPQL alone can't portably express.
     */
    public List<BookingTrendPoint> getBookingsTrend(int days) {
        List<Booking> bookings = bookingRepository.findByCreatedAtAfter(Instant.now().minus(days, ChronoUnit.DAYS));

        Map<LocalDate, Long> countsByDay = bookings.stream()
                .collect(Collectors.groupingBy(
                        b -> b.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate(),
                        TreeMap::new,
                        Collectors.counting()
                ));

        return countsByDay.entrySet().stream()
                .map(entry -> new BookingTrendPoint(entry.getKey(), entry.getValue()))
                .toList();
    }

    /** One point per ISO week (Monday start, UTC) with at least one new CUSTOMER or PROVIDER signup over the last `weeks` weeks. See UserGrowthPoint's doc comment for why ADMIN accounts don't count here. */
    public List<UserGrowthPoint> getUserGrowth(int weeks) {
        List<User> newUsers = userRepository.findByCreatedAtAfter(Instant.now().minus(weeks * 7L, ChronoUnit.DAYS));

        Map<LocalDate, long[]> countsByWeek = new TreeMap<>();
        for (User user : newUsers) {
            if (user.getRole() == Role.ADMIN) continue;

            LocalDate weekStart = user.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate()
                    .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
            long[] counts = countsByWeek.computeIfAbsent(weekStart, key -> new long[2]);
            if (user.getRole() == Role.CUSTOMER) {
                counts[0]++;
            } else {
                counts[1]++;
            }
        }

        return countsByWeek.entrySet().stream()
                .map(entry -> new UserGrowthPoint(entry.getKey(), entry.getValue()[0], entry.getValue()[1]))
                .toList();
    }
}
