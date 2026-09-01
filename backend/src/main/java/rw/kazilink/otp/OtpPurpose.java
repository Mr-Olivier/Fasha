package rw.kazilink.otp;

/** What a given OTP code is for - the same 6-digit-code mechanism serves both, but a code issued for one purpose must never verify the other. */
public enum OtpPurpose {
    EMAIL_VERIFICATION,
    PASSWORD_RESET
}
