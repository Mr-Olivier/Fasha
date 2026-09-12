package rw.kazilink.service;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** Only a PROVIDER can manage services, and only their own - see ServiceListingService for the ownership check. */
@RestController
@RequestMapping("/api/providers/me/services")
@RequiredArgsConstructor
public class ServiceListingController {

    private final ServiceListingService serviceListingService;

    @GetMapping
    @PreAuthorize("hasRole('PROVIDER')")
    public List<ServiceListingResponse> listMyServices(@AuthenticationPrincipal UUID userId) {
        return serviceListingService.listMyServices(userId);
    }

    @PostMapping
    @PreAuthorize("hasRole('PROVIDER')")
    public ResponseEntity<ServiceListingResponse> addService(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody UpsertServiceListingRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(serviceListingService.addService(userId, request));
    }

    @PutMapping("/{serviceId}")
    @PreAuthorize("hasRole('PROVIDER')")
    public ServiceListingResponse updateService(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID serviceId,
            @Valid @RequestBody UpsertServiceListingRequest request
    ) {
        return serviceListingService.updateService(userId, serviceId, request);
    }

    @PatchMapping("/{serviceId}/visibility")
    @PreAuthorize("hasRole('PROVIDER')")
    public ServiceListingResponse setVisibility(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID serviceId,
            @Valid @RequestBody UpdateServiceVisibilityRequest request
    ) {
        return serviceListingService.setVisibility(userId, serviceId, request.visible());
    }
}
