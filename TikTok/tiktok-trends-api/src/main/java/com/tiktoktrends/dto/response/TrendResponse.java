package com.tiktoktrends.dto.response;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

// ─── Trend ───────────────────────────────────────────────────────────────────
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TrendResponse {
    private UUID id;
    private String trendType;
    private String keyword;
    private Double velocityScore;
    private Double engagementAvg;
    private Long viewCountAvg;
    private LocalDateTime detectedAt;
    private LocalDateTime expiresAt;
}
