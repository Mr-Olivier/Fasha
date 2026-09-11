package rw.kazilink.admin;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import rw.kazilink.provider.VerificationStatus;

import java.util.List;
import java.util.UUID;

/**
 * Every endpoint here is admin-only (README.md section 10) - class-level
 * @PreAuthorize instead of repeating it per method, since there's no mixed
 * access on this controller the way ProviderProfileController has public
 * search alongside provider-only writes.
 */
@RestController
@RequestMapping("/api/admin/providers")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminProviderController {

    private final AdminProviderService adminProviderService;

    @GetMapping
    public List<PendingProviderResponse> list(@RequestParam(required = false) VerificationStatus status) {
        return adminProviderService.listProviders(status);
    }

    @PatchMapping("/{id}/approve")
    public PendingProviderResponse decide(
            @AuthenticationPrincipal UUID adminUserId,
            @PathVariable UUID id,
            @Valid @RequestBody ProviderDecisionRequest request
    ) {
        return adminProviderService.decide(adminUserId, id, request.approved());
    }
}
