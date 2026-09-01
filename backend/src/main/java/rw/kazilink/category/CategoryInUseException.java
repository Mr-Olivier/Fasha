package rw.kazilink.category;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AdminCategoryService.delete() when a service still references the category - the fk_services_category constraint would reject it anyway, but this gives the admin a clear reason instead of a raw DB error. */
public class CategoryInUseException extends ApplicationException {

    public CategoryInUseException() {
        super(HttpStatus.CONFLICT, "This category is still used by at least one service and can't be deleted.");
    }
}
