package rw.kazilink.provider;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by ProviderDocumentService.submitForReview when the required ID or selfie hasn't been uploaded yet. */
public class IncompleteDocumentsException extends ApplicationException {

    public IncompleteDocumentsException() {
        super(HttpStatus.BAD_REQUEST, "Upload your ID and a selfie holding it before submitting for review.");
    }
}
