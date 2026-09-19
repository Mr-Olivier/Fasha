package rw.fasha.admin;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/** One row per admin action worth remembering - see V21's migration comment for why this table exists. */
@Entity
@Table(name = "admin_audit_log")
@Getter
@NoArgsConstructor
public class AdminAuditLog {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "admin_user_id", nullable = false)
    private UUID adminUserId;

    @Column(nullable = false, length = 50)
    private String action;

    @Column(name = "target_type", nullable = false, length = 30)
    private String targetType;

    @Column(name = "target_id")
    private UUID targetId;

    @Column(length = 500)
    private String details;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    public AdminAuditLog(UUID adminUserId, String action, String targetType, UUID targetId, String details) {
        this.adminUserId = adminUserId;
        this.action = action;
        this.targetType = targetType;
        this.targetId = targetId;
        this.details = details;
        this.createdAt = Instant.now();
    }
}
