package rw.kazilink.admin;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.provider.VerificationStatus;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminStatsServiceTest {

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private BookingRepository bookingRepository;

    @InjectMocks
    private AdminStatsService adminStatsService;

    @Test
    void getStats_combinesCountsFromEachRepository() {
        when(providerProfileRepository.countByVerificationStatus(VerificationStatus.PENDING)).thenReturn(7L);
        when(providerProfileRepository.countByVerificationStatus(VerificationStatus.APPROVED)).thenReturn(142L);
        when(userRepository.countByRole(Role.CUSTOMER)).thenReturn(1284L);
        when(bookingRepository.countByCreatedAtAfter(any(Instant.class))).thenReturn(318L);

        AdminStatsResponse stats = adminStatsService.getStats();

        assertThat(stats.pendingApprovals()).isEqualTo(7);
        assertThat(stats.activeProviders()).isEqualTo(142);
        assertThat(stats.totalCustomers()).isEqualTo(1284);
        assertThat(stats.bookingsLast30Days()).isEqualTo(318);
    }

    private Booking bookingCreatedAt(Instant createdAt) {
        Booking booking = new Booking(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), null, null);
        booking.setCreatedAt(createdAt);
        return booking;
    }

    private User userCreatedAt(Role role, Instant createdAt) {
        User user = new User("Someone", "someone-" + UUID.randomUUID() + "@example.com", null, "hash", role);
        user.setCreatedAt(createdAt);
        return user;
    }

    @Test
    void getBookingsTrend_groupsBookingsByCalendarDayUtc() {
        Instant day1 = LocalDate.of(2026, 9, 1).atStartOfDay(ZoneOffset.UTC).toInstant().plusSeconds(3600);
        Instant day2 = LocalDate.of(2026, 9, 2).atStartOfDay(ZoneOffset.UTC).toInstant().plusSeconds(7200);
        when(bookingRepository.findByCreatedAtAfter(any(Instant.class))).thenReturn(List.of(
                bookingCreatedAt(day1), bookingCreatedAt(day1), bookingCreatedAt(day2)
        ));

        List<BookingTrendPoint> trend = adminStatsService.getBookingsTrend(30);

        assertThat(trend).hasSize(2);
        assertThat(trend.get(0).date()).isEqualTo(LocalDate.of(2026, 9, 1));
        assertThat(trend.get(0).count()).isEqualTo(2);
        assertThat(trend.get(1).date()).isEqualTo(LocalDate.of(2026, 9, 2));
        assertThat(trend.get(1).count()).isEqualTo(1);
    }

    @Test
    void getBookingsTrend_isEmptyWhenNoBookingsInTheWindow() {
        when(bookingRepository.findByCreatedAtAfter(any(Instant.class))).thenReturn(List.of());

        assertThat(adminStatsService.getBookingsTrend(30)).isEmpty();
    }

    @Test
    void getUserGrowth_groupsSignupsByWeekAndRoleExcludingAdmins() {
        // 2026-09-07 is a Monday.
        Instant mondayMorning = LocalDate.of(2026, 9, 7).atStartOfDay(ZoneOffset.UTC).toInstant().plusSeconds(3600);
        Instant sameWeekLater = LocalDate.of(2026, 9, 9).atStartOfDay(ZoneOffset.UTC).toInstant();
        when(userRepository.findByCreatedAtAfter(any(Instant.class))).thenReturn(List.of(
                userCreatedAt(Role.CUSTOMER, mondayMorning),
                userCreatedAt(Role.CUSTOMER, sameWeekLater),
                userCreatedAt(Role.PROVIDER, sameWeekLater),
                userCreatedAt(Role.ADMIN, sameWeekLater)
        ));

        List<UserGrowthPoint> growth = adminStatsService.getUserGrowth(12);

        assertThat(growth).hasSize(1);
        assertThat(growth.get(0).weekStart()).isEqualTo(LocalDate.of(2026, 9, 7));
        assertThat(growth.get(0).newCustomers()).isEqualTo(2);
        assertThat(growth.get(0).newProviders()).isEqualTo(1);
    }

    @Test
    void getUserGrowth_isEmptyWhenNoOneSignedUp() {
        when(userRepository.findByCreatedAtAfter(any(Instant.class))).thenReturn(List.of());

        assertThat(adminStatsService.getUserGrowth(12)).isEmpty();
    }
}
