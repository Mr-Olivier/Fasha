package rw.kazilink.user;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AvatarStorageService when the uploaded file isn't a usable image. */
public class InvalidAvatarException extends ApplicationException {

    public InvalidAvatarException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
