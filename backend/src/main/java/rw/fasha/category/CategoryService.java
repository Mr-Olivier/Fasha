package rw.fasha.category;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public List<CategoryResponse> listAll() {
        return categoryRepository.findByActiveTrueOrderByNameAsc().stream()
                .map(category -> new CategoryResponse(category.getId(), category.getName(), category.getDescription(), category.getImageUrl()))
                .toList();
    }
}
