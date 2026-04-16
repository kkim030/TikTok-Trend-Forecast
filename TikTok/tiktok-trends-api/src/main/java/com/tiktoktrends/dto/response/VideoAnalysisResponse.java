package com.tiktoktrends.dto.response;

import lombok.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class VideoAnalysisResponse {
    private UUID id;
    private LocalDateTime analyzedAt;
    private List<VideoSummary> topVideos;
    private String analysis;          // markdown
    private List<String> keyTakeaways;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class VideoSummary {
        private String videoId;
        private String title;
        private Long viewCount;
        private Double engagementRate;
        private String thumbnailUrl;
    }
}
