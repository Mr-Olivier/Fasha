package rw.kazilink.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BookingStatusHistoryRepository extends JpaRepository<BookingStatusHistory, UUID> {

    /** Powers the Booking Tracker timeline - oldest transition first. */
    List<BookingStatusHistory> findByBookingIdOrderByChangedAtAsc(UUID bookingId);
}
