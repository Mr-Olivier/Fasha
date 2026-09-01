package rw.kazilink.chat;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/** One chat message on a booking's conversation (maps to the "messages" table). Immutable once sent - no edit/delete. */
@Entity
@Table(name = "messages")
@Getter
@NoArgsConstructor
public class Message {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "booking_id", nullable = false)
    private UUID bookingId;

    @Column(name = "sender_id", nullable = false)
    private UUID senderId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public Message(UUID bookingId, UUID senderId, String body) {
        this.bookingId = bookingId;
        this.senderId = senderId;
        this.body = body;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
