package rw.kazilink.provider;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Only a PROVIDER can manage a provider profile - @PreAuthorize enforces
 * that using the role JwtAuthenticationFilter attached to this request's
 * token. @AuthenticationPrincipal hands us that same token's user id
 * directly as a UUID (that's literally what the filter set as the
 * "principal"), so there's no need to look anything up just to know
 * who's calling.
 */
@RestController
@RequestMapping("/api/providers")
@RequiredArgsConstructor
public class ProviderProfileController {

    private final ProviderProfileService providerProfileService;

    /** Public search - SecurityConfig permits GET here for everyone, logged in or not. */
    @GetMapping
    public List<ProviderProfileResponse> browseProviders(@RequestParam(required = false) UUID categoryId) {
        return providerProfileService.browseProviders(categoryId);
    }

    /** Public detail page - also permitAll in SecurityConfig. */
    @GetMapping("/{id}")
    public ProviderDetailResponse getProviderDetail(@PathVariable UUID id) {
        return providerProfileService.getProviderDetail(id);
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderProfileResponse getMyProfile(@AuthenticationPrincipal UUID userId) {
        return providerProfileService.getMyProfile(userId);
    }

    @PutMapping("/me")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderProfileResponse upsertMyProfile(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody UpsertProviderProfileRequest request
    ) {
        return providerProfileService.upsertMyProfile(userId, request);
    }
}
