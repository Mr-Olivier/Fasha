package rw.kazilink.chat;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MessageRepository extends JpaRepository<Message, UUID> {

    /** Powers GET /api/bookings/{bookingId}/messages - the whole conversation, oldest first. */
    List<Message> findByBookingIdOrderByCreatedAtAsc(UUID bookingId);
}
