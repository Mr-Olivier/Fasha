package rw.fasha.booking;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLConnection;
import java.util.List;
import java.util.UUID;

/**
 * No @PreAuthorize role check here - a photo can legitimately be attached
 * or viewed by either a CUSTOMER or a PROVIDER, just for their own
 * booking. BookingPhotoService.findAccessible does the actual check (is
 * this caller one of THIS booking's two parties), the same "no role param
 * to lie about" reasoning BookingController's own GET endpoints already
 * use.
 */
@RestController
@RequestMapping("/api/bookings/{bookingId}/photos")
@RequiredArgsConstructor
public class BookingPhotoController {

    private final BookingPhotoService bookingPhotoService;

    @PostMapping
    public ResponseEntity<BookingPhotoResponse> upload(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID bookingId,
            @RequestParam("file") MultipartFile file
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(bookingPhotoService.upload(userId, bookingId, file));
    }

    @GetMapping
    public List<BookingPhotoResponse> list(@AuthenticationPrincipal UUID userId, @PathVariable UUID bookingId) {
        return bookingPhotoService.list(userId, bookingId);
    }

    @GetMapping("/{photoId}")
    public ResponseEntity<Resource> download(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID bookingId,
            @PathVariable UUID photoId
    ) {
        Resource resource = bookingPhotoService.download(userId, bookingId, photoId);
        String contentType = URLConnection.guessContentTypeFromName(resource.getFilename());
        return ResponseEntity.ok()
                .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }
}
