package rw.fasha.chat;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface MessageRepository extends JpaRepository<Message, UUID> {

    /** Powers GET /api/bookings/{bookingId}/messages - the whole conversation, oldest first. */
    List<Message> findByBookingIdOrderByCreatedAtAsc(UUID bookingId);

    /** The other party's unread messages - what MessageService.list() marks read whenever the caller opens this conversation. */
    List<Message> findByBookingIdAndSenderIdNotAndReadFalse(UUID bookingId, UUID callerId);
}
