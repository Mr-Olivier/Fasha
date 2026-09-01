package rw.kazilink.admin;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.category.Category;
import rw.kazilink.category.CategoryInUseException;
import rw.kazilink.category.CategoryNameAlreadyExistsException;
import rw.kazilink.category.CategoryNotFoundException;
import rw.kazilink.category.CategoryRepository;
import rw.kazilink.category.CategoryResponse;
import rw.kazilink.service.ServiceListingRepository;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminCategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @InjectMocks
    private AdminCategoryService adminCategoryService;

    private final UUID categoryId = UUID.randomUUID();

    @Test
    void create_savesANewCategoryWhenTheNameIsFree() {
        when(categoryRepository.existsByNameIgnoreCase("Plumber")).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CategoryResponse response = adminCategoryService.create("Plumber", "Pipe and tap repairs");

        assertThat(response.name()).isEqualTo("Plumber");
        assertThat(response.description()).isEqualTo("Pipe and tap repairs");
    }

    @Test
    void create_throwsWhenTheNameAlreadyExists() {
        when(categoryRepository.existsByNameIgnoreCase("Plumber")).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.create("Plumber", null))
                .isInstanceOf(CategoryNameAlreadyExistsException.class);
        verify(categoryRepository, never()).save(any());
    }

    @Test
    void update_renamesAnExistingCategory() {
        Category category = new Category("Cleaner", "Old description");
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRepository.existsByNameIgnoreCaseAndIdNot("Home Cleaner", categoryId)).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CategoryResponse response = adminCategoryService.update(categoryId, "Home Cleaner", "New description");

        assertThat(response.name()).isEqualTo("Home Cleaner");
        assertThat(response.description()).isEqualTo("New description");
    }

    @Test
    void update_throwsWhenTheCategoryDoesNotExist() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminCategoryService.update(categoryId, "Whatever", null))
                .isInstanceOf(CategoryNotFoundException.class);
    }

    @Test
    void update_throwsWhenRenamingToANameAnotherCategoryAlreadyHas() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRepository.existsByNameIgnoreCaseAndIdNot("Electrician", categoryId)).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.update(categoryId, "Electrician", null))
                .isInstanceOf(CategoryNameAlreadyExistsException.class);
    }

    @Test
    void delete_removesACategoryNoServiceUses() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(serviceListingRepository.existsByCategoryId(categoryId)).thenReturn(false);

        adminCategoryService.delete(categoryId);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository).delete(captor.capture());
        assertThat(captor.getValue()).isSameAs(category);
    }

    @Test
    void delete_throwsWhenAServiceStillUsesTheCategory() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(serviceListingRepository.existsByCategoryId(categoryId)).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.delete(categoryId))
                .isInstanceOf(CategoryInUseException.class);
        verify(categoryRepository, never()).delete(any());
    }

    @Test
    void delete_throwsWhenTheCategoryDoesNotExist() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminCategoryService.delete(categoryId))
                .isInstanceOf(CategoryNotFoundException.class);
    }
}
