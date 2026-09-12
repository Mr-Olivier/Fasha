package rw.kazilink.common;

import org.springframework.http.HttpStatus;

/** Thrown by SecureFileStorageService when the uploaded file isn't a usable image or PDF. */
public class InvalidSecureUploadException extends ApplicationException {

    public InvalidSecureUploadException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
