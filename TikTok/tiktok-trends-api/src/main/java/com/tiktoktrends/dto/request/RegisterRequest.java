package com.tiktoktrends.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor
public class RegisterRequest {

    @NotBlank
    private String tiktokHandle;

    @NotBlank @Email
    private String email;

    @NotBlank @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;

    private String niche;   // e.g. "fitness", "cooking", "gaming"
}
