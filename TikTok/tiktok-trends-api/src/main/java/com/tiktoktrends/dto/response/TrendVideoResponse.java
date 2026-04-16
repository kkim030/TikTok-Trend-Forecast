package com.tiktoktrends.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data @Builder
public class TrendVideoResponse {
    private String videoId;
    private String thumbnailUrl;
    private Long viewCount;
    private Long likeCount;
    private Long shareCount;
    private String creatorHandle;
    private String creatorAvatarUrl;
    private String description;
    private String videoUrl;
    private LocalDateTime publishedAt;

    @Data @Builder
    public static class Wrapper {
        private String trendId;
        private List<TrendVideoResponse> videos;
    }
}
