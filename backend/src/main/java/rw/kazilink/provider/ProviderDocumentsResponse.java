package rw.kazilink.provider;

import java.time.Instant;

/**
 * Whether each KYC slot has been uploaded - booleans ONLY, never a raw
 * file path (see SecureFileStorageService's doc comment). The provider's
 * own "Get verified" screen uses these to render a checkmark per slot;
 * the actual bytes are only ever fetched through
 * GET /api/providers/{id}/documents/{type}, by the owner or an admin.
 */
public record ProviderDocumentsResponse(
        boolean idDocumentUploaded,
        boolean tradeCertificateUploaded,
        boolean selfieUploaded,
        Instant documentsSubmittedAt,
        VerificationStatus verificationStatus
) {

    public static ProviderDocumentsResponse from(ProviderProfile profile) {
        return new ProviderDocumentsResponse(
                profile.getIdDocumentPath() != null,
                profile.getTradeCertificatePath() != null,
                profile.getSelfieWithIdPath() != null,
                profile.getDocumentsSubmittedAt(),
                profile.getVerificationStatus()
        );
    }
}
