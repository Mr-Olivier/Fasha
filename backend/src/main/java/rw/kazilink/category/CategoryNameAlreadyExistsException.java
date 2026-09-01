package rw.kazilink.category;

import org.springframework.http.HttpStatus;
import rw.kazilink.common.ApplicationException;

/** Thrown by AdminCategoryService.create()/update() when the name clashes with the categories_table's unique constraint. */
public class CategoryNameAlreadyExistsException extends ApplicationException {

    public CategoryNameAlreadyExistsException(String name) {
        super(HttpStatus.CONFLICT, "A category named '" + name + "' already exists.");
    }
}
