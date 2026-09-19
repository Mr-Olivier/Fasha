package rw.fasha.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLConnection;
import java.util.UUID;

@RestController
@RequestMapping("/api/providers")
@RequiredArgsConstructor
public class ProviderDocumentController {

    private final ProviderDocumentService providerDocumentService;

    @PostMapping("/me/documents/id")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderDocumentsResponse uploadId(@AuthenticationPrincipal UUID userId, @RequestParam("file") MultipartFile file) {
        return providerDocumentService.uploadDocument(userId, DocumentType.ID, file);
    }

    @PostMapping("/me/documents/trade-certificate")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderDocumentsResponse uploadTradeCertificate(
            @AuthenticationPrincipal UUID userId, @RequestParam("file") MultipartFile file
    ) {
        return providerDocumentService.uploadDocument(userId, DocumentType.TRADE_CERTIFICATE, file);
    }

    @PostMapping("/me/documents/selfie")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderDocumentsResponse uploadSelfie(@AuthenticationPrincipal UUID userId, @RequestParam("file") MultipartFile file) {
        return providerDocumentService.uploadDocument(userId, DocumentType.SELFIE, file);
    }

    @PostMapping("/me/documents/submit")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderDocumentsResponse submit(@AuthenticationPrincipal UUID userId) {
        return providerDocumentService.submitForReview(userId);
    }

    @GetMapping("/me/documents")
    @PreAuthorize("hasRole('PROVIDER')")
    public ProviderDocumentsResponse getMyDocuments(@AuthenticationPrincipal UUID userId) {
        return providerDocumentService.getMyDocumentsStatus(userId);
    }

    /**
     * Owner-or-admin, checked in the service layer rather than SpEL (same
     * preference the rest of this codebase already has for ownership
     * checks - see BookingService.findOwnedByProvider) - so both an
     * unauthenticated stranger and a DIFFERENT provider get the exact same
     * 404 a genuinely-missing id would.
     */
    @GetMapping("/{providerProfileId}/documents/{type}")
    public ResponseEntity<Resource> viewDocument(
            @AuthenticationPrincipal UUID userId,
            Authentication authentication,
            @PathVariable UUID providerProfileId,
            @PathVariable DocumentType type
    ) {
        boolean isAdmin = authentication.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN"));
        Resource resource = providerDocumentService.streamDocument(userId, isAdmin, providerProfileId, type);
        String contentType = URLConnection.guessContentTypeFromName(resource.getFilename());
        return ResponseEntity.ok()
                .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }

    /** Frees server storage once admin's done reviewing - see ProviderDocumentService.deleteDocument's doc comment. */
    @DeleteMapping("/{providerProfileId}/documents/{type}")
    @PreAuthorize("hasRole('ADMIN')")
    public ProviderDocumentsResponse deleteDocument(
            @AuthenticationPrincipal UUID adminUserId,
            @PathVariable UUID providerProfileId,
            @PathVariable DocumentType type
    ) {
        return providerDocumentService.deleteDocument(adminUserId, providerProfileId, type);
    }
}
