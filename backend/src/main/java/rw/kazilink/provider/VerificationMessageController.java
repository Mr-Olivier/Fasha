package rw.kazilink.provider;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * The provider's own side always uses /me (it never needs to know its own
 * providerProfileId just to open this thread); admin always uses the
 * explicit id, since one admin account reads/replies to many providers'
 * threads. See VerificationMessageService's doc comment for why "admin"
 * isn't one specific reviewer.
 */
@RestController
@RequestMapping("/api/providers")
@RequiredArgsConstructor
public class VerificationMessageController {

    private final VerificationMessageService verificationMessageService;

    @GetMapping("/me/verification-messages")
    @PreAuthorize("hasRole('PROVIDER')")
    public List<VerificationMessageResponse> listMine(@AuthenticationPrincipal UUID userId) {
        return verificationMessageService.listForProvider(userId);
    }

    @PostMapping("/me/verification-messages")
    @PreAuthorize("hasRole('PROVIDER')")
    public ResponseEntity<VerificationMessageResponse> sendMine(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody SendVerificationMessageRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(verificationMessageService.sendAsProvider(userId, request.body()));
    }

    @GetMapping("/{providerProfileId}/verification-messages")
    @PreAuthorize("hasRole('ADMIN')")
    public List<VerificationMessageResponse> listForAdmin(@PathVariable UUID providerProfileId) {
        return verificationMessageService.listForAdmin(providerProfileId);
    }

    @PostMapping("/{providerProfileId}/verification-messages")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VerificationMessageResponse> sendAsAdmin(
            @AuthenticationPrincipal UUID adminUserId,
            @PathVariable UUID providerProfileId,
            @Valid @RequestBody SendVerificationMessageRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(verificationMessageService.sendAsAdmin(adminUserId, providerProfileId, request.body()));
    }
}
