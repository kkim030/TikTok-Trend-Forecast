package com.tiktoktrends.dto.response;

import lombok.*;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AuthResponse {
    private String token;
    private UUID userId;
    private String tiktokHandle;
    private String niche;
    private String displayName;
    private String avatarUrl;
}
