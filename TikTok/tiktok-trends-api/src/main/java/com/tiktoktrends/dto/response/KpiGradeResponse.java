package com.tiktoktrends.dto.response;

import lombok.*;
import java.util.List;

// ─── KPI Grades (scorecard) ───────────────────────────────────────────────────
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class KpiGradeResponse {
    private String engagementRate;    // A/B/C/D/F
    private String viewVelocity;
    private String followerGrowth;
    private String watchTime;
    private String shareRate;
    private String overall;
}
