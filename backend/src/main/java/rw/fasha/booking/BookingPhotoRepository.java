package rw.fasha.booking;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface BookingPhotoRepository extends JpaRepository<BookingPhoto, UUID> {

    List<BookingPhoto> findByBookingIdOrderByCreatedAtAsc(UUID bookingId);
}
