package rw.fasha.category;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private CategoryService categoryService;

    @Test
    void listAll_mapsEntitiesToResponsesInRepositoryOrder() {
        when(categoryRepository.findByActiveTrueOrderByNameAsc()).thenReturn(List.of(
                new Category("Cleaner", "Home and office cleaning"),
                new Category("Electrician", "Electrical repairs")
        ));

        List<CategoryResponse> result = categoryService.listAll();

        assertThat(result).hasSize(2);
        assertThat(result.get(0).name()).isEqualTo("Cleaner");
        assertThat(result.get(1).name()).isEqualTo("Electrician");
    }
}
