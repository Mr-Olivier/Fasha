package rw.kazilink.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface BookingRepository extends JpaRepository<Booking, UUID> {

    List<Booking> findByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    List<Booking> findByProviderProfileIdOrderByCreatedAtDesc(UUID providerProfileId);

    /** Powers the provider's "completed jobs & earnings" screen (D8). */
    List<Booking> findByProviderProfileIdAndStatusOrderByUpdatedAtDesc(UUID providerProfileId, BookingStatus status);

    /** Guards AdminUserService.delete() for a CUSTOMER account - one with any booking history can't be permanently removed, only suspended. */
    boolean existsByCustomerId(UUID customerId);

    /** Guards AdminUserService.delete() for a PROVIDER account - same reasoning as existsByCustomerId. */
    boolean existsByProviderProfileId(UUID providerProfileId);

    /** Powers the admin category list's "bookings" count - every booking ever made for a service in that category. */
    long countByServiceListingIdIn(Collection<UUID> serviceListingIds);

    /** Powers the admin overview's "Bookings (30d)" stat. */
    long countByCreatedAtAfter(Instant createdAfter);

    /** Powers the admin dashboard's "Bookings trend" chart - AdminStatsService buckets these by day in memory (see its doc comment for why that's fine at this scale). */
    List<Booking> findByCreatedAtAfter(Instant createdAfter);
}
