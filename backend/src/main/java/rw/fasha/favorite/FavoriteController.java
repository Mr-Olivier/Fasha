package rw.fasha.favorite;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import rw.fasha.provider.ProviderProfileResponse;
import rw.fasha.provider.ProviderProfileService;

import java.util.List;
import java.util.UUID;

/** Only a CUSTOMER favorites providers - a provider or admin has no use for this list. */
@RestController
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;
    private final ProviderProfileService providerProfileService;

    @PostMapping("/api/providers/{id}/favorite")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Void> favorite(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        favoriteService.add(userId, id);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }

    @DeleteMapping("/api/providers/{id}/favorite")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<Void> unfavorite(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        favoriteService.remove(userId, id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/api/favorites")
    @PreAuthorize("hasRole('CUSTOMER')")
    public List<ProviderProfileResponse> listFavorites(@AuthenticationPrincipal UUID userId) {
        return providerProfileService.listFavoriteProviders(userId);
    }
}
