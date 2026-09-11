package rw.kazilink.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Writes and reads the admin action audit trail (see V21's migration
 * comment for why it exists). Every admin-only mutation that changes an
 * account or a category's state should call [record] right after the
 * write succeeds - approve/reject a provider, suspend/resume/delete a
 * user, add/hide/delete a category.
 */
@Service
@RequiredArgsConstructor
public class AdminAuditService {

    private final AdminAuditLogRepository auditLogRepository;
    private final UserRepository userRepository;

    public void record(UUID adminUserId, String action, String targetType, UUID targetId, String details) {
        auditLogRepository.save(new AdminAuditLog(adminUserId, action, targetType, targetId, details));
    }

    /** Powers a simple "recent activity" admin screen - newest first, capped at `limit` rows (no pagination UI exists yet, so a generous single page is enough). */
    public List<AdminAuditLogResponse> listRecent(int limit) {
        List<AdminAuditLog> entries = auditLogRepository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, limit)).getContent();

        Map<UUID, String> adminNamesById = userRepository.findAllById(entries.stream().map(AdminAuditLog::getAdminUserId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(User::getId, User::getName));

        return entries.stream()
                .map(entry -> new AdminAuditLogResponse(
                        entry.getId(),
                        adminNamesById.getOrDefault(entry.getAdminUserId(), "Unknown admin"),
                        entry.getAction(),
                        entry.getTargetType(),
                        entry.getTargetId(),
                        entry.getDetails(),
                        entry.getCreatedAt()
                ))
                .toList();
    }
}
