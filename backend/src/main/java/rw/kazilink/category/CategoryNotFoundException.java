package rw.kazilink.category;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AdminCategoryService when a PATCH/DELETE targets a category id that doesn't exist. */
public class CategoryNotFoundException extends ApplicationException {

    public CategoryNotFoundException() {
        super(HttpStatus.NOT_FOUND, "That category does not exist.");
    }
}
