package com.tiktoktrends.dto.response;

import lombok.*;
import java.util.List;

// ─── Full comparison payload (powers all 3 chart views) ──────────────────────
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PerformanceComparisonResponse {
    private List<PerformanceSnapshotResponse> userSnapshots;   // user's own data
    private List<PerformanceSnapshotResponse> benchmarks;      // public trend averages
    private KpiGradeResponse currentGrades;                    // scorecard grades
}
