package rw.fasha.provider;

/**
 * Every new profile starts PENDING. Only an admin can move it to APPROVED
 * or REJECTED (Feature 9, not built yet) - a provider can never set their
 * own verification status, which is why UpsertProviderProfileRequest has
 * no field for it at all.
 */
public enum VerificationStatus {
    PENDING,
    APPROVED,
    REJECTED
}
