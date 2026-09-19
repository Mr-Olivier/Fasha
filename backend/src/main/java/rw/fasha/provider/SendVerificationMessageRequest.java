package rw.fasha.provider;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendVerificationMessageRequest(
        @NotBlank(message = "Message can't be empty")
        @Size(max = 2000, message = "Message must be at most 2000 characters")
        String body
) {
}
