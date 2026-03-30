package com.tiktoktrends.dto.response;

import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

// ─── Single weekly snapshot (used for both user data and benchmark) ───────────
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PerformanceSnapshotResponse {
    private LocalDateTime periodStart;
    private LocalDateTime periodEnd;
    private Double engagementRate;    // KPI 1
    private Double viewVelocity;      // KPI 2
    private Double followerGrowthRate;// KPI 3
    private Double avgWatchTimePct;   // KPI 4
    private Double shareRate;         // KPI 5
    private Long followerCount;
    private Long totalViews;
}
