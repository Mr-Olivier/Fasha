package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import rw.kazilink.common.SecureFileStorageService;

import java.time.Instant;
import java.util.UUID;

/**
 * KYC document upload/review for provider verification (D7 "Get
 * verified"). Every document is stored via SecureFileStorageService -
 * private, never a public URL - and only ever streamed back to the owning
 * provider or an ADMIN (see streamDocument), per the provider-tools plan's
 * decision #1.
 */
@Service
@RequiredArgsConstructor
public class ProviderDocumentService {

    private final ProviderProfileRepository providerProfileRepository;
    private final SecureFileStorageService fileStorageService;

    @Transactional
    public ProviderDocumentsResponse uploadDocument(UUID userId, DocumentType type, MultipartFile file) {
        ProviderProfile profile = resolveOwnProfile(userId);
        String storagePath = fileStorageService.store("kyc", profile.getId().toString(), file);
        switch (type) {
            case ID -> profile.setIdDocumentPath(storagePath);
            case TRADE_CERTIFICATE -> profile.setTradeCertificatePath(storagePath);
            case SELFIE -> profile.setSelfieWithIdPath(storagePath);
        }
        providerProfileRepository.save(profile);
        return ProviderDocumentsResponse.from(profile);
    }

    /**
     * Requires the ID and selfie (trade certificate stays optional - not
     * every provider is a registered company). A provider who was
     * previously REJECTED and re-submits goes back to PENDING, re-entering
     * the admin queue instead of staying stuck as REJECTED forever.
     */
    @Transactional
    public ProviderDocumentsResponse submitForReview(UUID userId) {
        ProviderProfile profile = resolveOwnProfile(userId);
        if (profile.getIdDocumentPath() == null || profile.getSelfieWithIdPath() == null) {
            throw new IncompleteDocumentsException();
        }
        profile.setDocumentsSubmittedAt(Instant.now());
        if (profile.getVerificationStatus() == VerificationStatus.REJECTED) {
            profile.setVerificationStatus(VerificationStatus.PENDING);
        }
        providerProfileRepository.save(profile);
        return ProviderDocumentsResponse.from(profile);
    }

    public ProviderDocumentsResponse getMyDocumentsStatus(UUID userId) {
        return ProviderDocumentsResponse.from(resolveOwnProfile(userId));
    }

    /** Owner-or-admin only - see ProviderDocumentController for how [callerIsAdmin] gets decided. */
    public Resource streamDocument(UUID callerUserId, boolean callerIsAdmin, UUID providerProfileId, DocumentType type) {
        ProviderProfile profile = providerProfileRepository.findById(providerProfileId)
                .orElseThrow(ProviderProfileNotFoundException::new);
        boolean isOwner = profile.getUserId().equals(callerUserId);
        if (!isOwner && !callerIsAdmin) {
            throw new ProviderProfileNotFoundException();
        }

        String storagePath = switch (type) {
            case ID -> profile.getIdDocumentPath();
            case TRADE_CERTIFICATE -> profile.getTradeCertificatePath();
            case SELFIE -> profile.getSelfieWithIdPath();
        };
        if (storagePath == null) {
            throw new ProviderProfileNotFoundException();
        }
        return fileStorageService.load(storagePath);
    }

    private ProviderProfile resolveOwnProfile(UUID userId) {
        return providerProfileRepository.findByUserId(userId).orElseThrow(ProviderProfileNotFoundException::new);
    }
}
