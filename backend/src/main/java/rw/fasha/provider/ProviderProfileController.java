package rw.fasha.provider;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
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

    /**
     * Public search - SecurityConfig permits GET here for everyone, logged
     * in or not. [search] matches against business name, location, and
     * description (see ProviderProfileService.browseProviders); all
     * filters combine (AND), so a category tap followed by typing a search
     * term narrows further rather than replacing the category filter.
     *
     * userId is only ever non-null when the caller sent a valid JWT for a
     * logged-in user (see JwtAuthenticationFilter) - an anonymous request
     * simply gets it as null, which browseProviders treats as "mark
     * nothing as favorited" rather than an error.
     */
    @GetMapping
    public List<ProviderProfileResponse> browseProviders(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Double minRating,
            @RequestParam(required = false) BigDecimal maxPrice
    ) {
        return providerProfileService.browseProviders(categoryId, search, minRating, maxPrice, userId);
    }

    /** Public detail page - also permitAll in SecurityConfig. */
    @GetMapping("/{id}")
    public ProviderDetailResponse getProviderDetail(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        return providerProfileService.getProviderDetail(id, userId);
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

    @PostMapping("/me/photo")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderProfileResponse updatePhoto(@AuthenticationPrincipal UUID userId, @RequestParam("file") MultipartFile file) {
        return providerProfileService.updatePhoto(userId, file);
    }
}
