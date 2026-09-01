package rw.kazilink.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.category.Category;
import rw.kazilink.category.CategoryInUseException;
import rw.kazilink.category.CategoryNameAlreadyExistsException;
import rw.kazilink.category.CategoryNotFoundException;
import rw.kazilink.category.CategoryRepository;
import rw.kazilink.category.CategoryResponse;
import rw.kazilink.service.ServiceListingRepository;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminCategoryService {

    private final CategoryRepository categoryRepository;
    private final ServiceListingRepository serviceListingRepository;

    @Transactional
    public CategoryResponse create(String name, String description) {
        if (categoryRepository.existsByNameIgnoreCase(name)) {
            throw new CategoryNameAlreadyExistsException(name);
        }
        Category saved = categoryRepository.save(new Category(name, description));
        return toResponse(saved);
    }

    @Transactional
    public CategoryResponse update(UUID id, String name, String description) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw new CategoryNameAlreadyExistsException(name);
        }
        category.rename(name, description);
        return toResponse(categoryRepository.save(category));
    }

    @Transactional
    public void delete(UUID id) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        if (serviceListingRepository.existsByCategoryId(id)) {
            throw new CategoryInUseException();
        }
        categoryRepository.delete(category);
    }

    private CategoryResponse toResponse(Category category) {
        return new CategoryResponse(category.getId(), category.getName(), category.getDescription());
    }
}
