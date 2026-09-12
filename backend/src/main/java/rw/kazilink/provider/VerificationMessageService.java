package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;

import java.util.List;
import java.util.UUID;

/**
 * A two-way conversation between one provider and admin about their
 * verification (D7) - not tied to any booking, so it can't reuse the
 * existing per-booking chat (rw.kazilink.chat). "Admin" isn't one specific
 * person: whichever admin sends a message, EVERY admin gets notified, and
 * any admin can read/reply to any provider's thread - there's no concept
 * of an "assigned" reviewer.
 */
@Service
@RequiredArgsConstructor
public class VerificationMessageService {

    private static final int NOTIFICATION_PREVIEW_LENGTH = 80;

    private final VerificationMessageRepository verificationMessageRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public List<VerificationMessageResponse> listForProvider(UUID userId) {
        return list(resolveOwnProfileId(userId));
    }

    /** Admin can open any provider's thread by id - no ownership check needed, @PreAuthorize on the controller already requires ADMIN. */
    public List<VerificationMessageResponse> listForAdmin(UUID providerProfileId) {
        requireProviderExists(providerProfileId);
        return list(providerProfileId);
    }

    @Transactional
    public VerificationMessageResponse sendAsProvider(UUID userId, String body) {
        UUID providerProfileId = resolveOwnProfileId(userId);
        VerificationMessage message = save(providerProfileId, userId, Role.PROVIDER, body);
        notifyAdmins(userId, body);
        return toResponse(message);
    }

    @Transactional
    public VerificationMessageResponse sendAsAdmin(UUID adminUserId, UUID providerProfileId, String body) {
        VerificationMessage message = save(providerProfileId, adminUserId, Role.ADMIN, body);
        notifyProvider(providerProfileId, adminUserId, body);
        return toResponse(message);
    }

    private VerificationMessage save(UUID providerProfileId, UUID senderId, Role role, String body) {
        requireProviderExists(providerProfileId);
        return verificationMessageRepository.save(new VerificationMessage(providerProfileId, senderId, role, body));
    }

    private List<VerificationMessageResponse> list(UUID providerProfileId) {
        return verificationMessageRepository.findByProviderProfileIdOrderByCreatedAtAsc(providerProfileId).stream()
                .map(this::toResponse)
                .toList();
    }

    private void notifyAdmins(UUID senderId, String body) {
        User sender = userRepository.findById(senderId).orElseThrow(UserNotFoundException::new);
        for (User admin : userRepository.findByRoleOrderByCreatedAtDesc(Role.ADMIN)) {
            notificationService.create(admin.getId(), "Verification message from " + sender.getName(), preview(body), null);
        }
    }

    private void notifyProvider(UUID providerProfileId, UUID senderId, String body) {
        ProviderProfile profile = providerProfileRepository.findById(providerProfileId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        User sender = userRepository.findById(senderId).orElseThrow(UserNotFoundException::new);
        notificationService.create(
                profile.getUserId(), "Message from " + sender.getName() + " about your verification", preview(body), null);
    }

    private void requireProviderExists(UUID providerProfileId) {
        if (!providerProfileRepository.existsById(providerProfileId)) {
            throw new ProviderProfileNotFoundException();
        }
    }

    private UUID resolveOwnProfileId(UUID userId) {
        return providerProfileRepository.findByUserId(userId).orElseThrow(ProviderProfileNotFoundException::new).getId();
    }

    private String preview(String body) {
        return body.length() <= NOTIFICATION_PREVIEW_LENGTH ? body : body.substring(0, NOTIFICATION_PREVIEW_LENGTH - 3) + "...";
    }

    private VerificationMessageResponse toResponse(VerificationMessage message) {
        User sender = userRepository.findById(message.getSenderId()).orElseThrow(UserNotFoundException::new);
        return new VerificationMessageResponse(
                message.getId(),
                message.getProviderProfileId(),
                message.getSenderId(),
                sender.getName(),
                message.getSenderRole(),
                message.getBody(),
                message.getCreatedAt()
        );
    }
}
