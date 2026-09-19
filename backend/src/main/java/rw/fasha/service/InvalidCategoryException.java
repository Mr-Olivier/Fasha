package rw.fasha.service;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown when a service is created/updated with a categoryId that doesn't exist - a client input error, hence 400. */
public class InvalidCategoryException extends ApplicationException {

    public InvalidCategoryException() {
        super(HttpStatus.BAD_REQUEST, "The selected category does not exist.");
    }
}
