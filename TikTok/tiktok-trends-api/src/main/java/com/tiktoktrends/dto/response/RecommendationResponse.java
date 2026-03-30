package com.tiktoktrends.dto.response;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class RecommendationResponse {
    private UUID id;
    private String conceptTitle;
    private String conceptDescription;
    private String suggestedMusic;
    private List<String> suggestedHashtags;
    private Double confidenceScore;
    private LocalDateTime generatedAt;
}
