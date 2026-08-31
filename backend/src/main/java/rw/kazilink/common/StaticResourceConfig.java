package rw.kazilink.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Path;

/**
 * Makes files saved by AvatarStorageService downloadable again over HTTP.
 *
 * Without this, POST /api/users/me/avatar would happily write a file to
 * disk, but the URL it returns (e.g. "/uploads/avatars/xyz.jpg") would be a
 * dead link - Spring only serves its own bundled static resources
 * automatically, not arbitrary folders on disk. "file:" (vs "classpath:")
 * tells Spring this location is a real filesystem path, not inside the jar.
 */
@Configuration
public class StaticResourceConfig implements WebMvcConfigurer {

    private final String uploadsDir;

    public StaticResourceConfig(@Value("${app.uploads-dir:uploads}") String uploadsDir) {
        this.uploadsDir = uploadsDir;
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = Path.of(uploadsDir).toAbsolutePath().toUri().toString();
        registry.addResourceHandler("/uploads/**").addResourceLocations(location);
    }
}
