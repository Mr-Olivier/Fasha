package rw.kazilink.chat;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * One chat message on a booking's conversation (maps to the "messages"
 * table). The body/attachment/sender/timing are immutable once sent - no
 * edit/delete; only {@link #read} ever changes, when the recipient opens
 * the conversation (see {@link MessageService#list}).
 *
 * A message carries EITHER a text body, an attachment (photo/short video),
 * or both - never neither (see V35's CHECK constraint). attachmentPath is
 * an opaque path into the private upload directory, same "never a public
 * URL" reasoning as BookingPhoto.storagePath - see SecureFileStorageService.
 */
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

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "attachment_path", length = 500)
    private String attachmentPath;

    @Enumerated(EnumType.STRING)
    @Column(name = "attachment_type", length = 20)
    private MessageAttachmentType attachmentType;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private boolean read;

    public Message(UUID bookingId, UUID senderId, String body) {
        this(bookingId, senderId, body, null, null);
    }

    public Message(UUID bookingId, UUID senderId, String body, String attachmentPath, MessageAttachmentType attachmentType) {
        this.bookingId = bookingId;
        this.senderId = senderId;
        this.body = body;
        this.attachmentPath = attachmentPath;
        this.attachmentType = attachmentType;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    void markRead() {
        this.read = true;
    }
}
