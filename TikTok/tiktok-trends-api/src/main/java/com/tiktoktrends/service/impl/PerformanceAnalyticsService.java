package com.tiktoktrends.service.impl;

import com.tiktoktrends.dto.response.KpiGradeResponse;
import com.tiktoktrends.dto.response.PerformanceComparisonResponse;
import com.tiktoktrends.dto.response.PerformanceSnapshotResponse;
import com.tiktoktrends.entity.TrendBenchmark;
import com.tiktoktrends.entity.UserKpiGrade;
import com.tiktoktrends.entity.UserPerformanceSnapshot;
import com.tiktoktrends.repository.TrendBenchmarkRepository;
import com.tiktoktrends.repository.UserKpiGradeRepository;
import com.tiktoktrends.repository.UserPerformanceSnapshotRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PerformanceAnalyticsService {

    private final UserPerformanceSnapshotRepository snapshotRepo;
    private final TrendBenchmarkRepository benchmarkRepo;
    private final UserKpiGradeRepository gradeRepo;

    /**
     * Returns 6 months of weekly snapshots for the chart,
     * alongside benchmark data for the same period.
     * Cached for 1 hour — same TTL as Redis config.
     */
    @Cacheable(value = "performanceComparison", key = "#userId")
    public PerformanceComparisonResponse getPerformanceComparison(UUID userId) {
        LocalDateTime sixMonthsAgo = LocalDateTime.now().minusMonths(6);

        List<UserPerformanceSnapshot> snapshots =
                snapshotRepo.findByUserIdSince(userId, sixMonthsAgo);

        List<TrendBenchmark> benchmarks =
                benchmarkRepo.findBenchmarksSince(sixMonthsAgo);

        List<PerformanceSnapshotResponse> snapshotDtos = snapshots.stream()
                .map(this::toSnapshotDto)
                .collect(Collectors.toList());

        List<PerformanceSnapshotResponse> benchmarkDtos = benchmarks.stream()
                .map(this::toBenchmarkDto)
                .collect(Collectors.toList());

        // Current grades (most recent snapshot)
        KpiGradeResponse grades = snapshots.isEmpty() ? null
                : getLatestGrades(snapshots.get(snapshots.size() - 1).getId());

        return PerformanceComparisonResponse.builder()
                .userSnapshots(snapshotDtos)
                .benchmarks(benchmarkDtos)
                .currentGrades(grades)
                .build();
    }

    /**
     * Computes grades by comparing a user snapshot vs the latest benchmark.
     * Grading scale: A ≥ 120% of benchmark, B ≥ 100%, C ≥ 80%, D ≥ 60%, F < 60%
     */
    public UserKpiGrade computeAndSaveGrades(UserPerformanceSnapshot snapshot,
                                              TrendBenchmark benchmark) {
        String engGrade  = grade(snapshot.getEngagementRate(),  benchmark.getAvgEngagementRate());
        String velGrade  = grade(snapshot.getViewVelocity(),    benchmark.getAvgViewVelocity());
        String growGrade = grade(snapshot.getFollowerGrowthRate(), benchmark.getAvgFollowerGrowth());
        String watchGrade = gradeWatch(snapshot.getAvgWatchTimePct()); // no benchmark — absolute scale
        String shareGrade = grade(snapshot.getShareRate(),      benchmark.getAvgShareRate());

        String overall = overallGrade(engGrade, velGrade, growGrade, watchGrade, shareGrade);

        UserKpiGrade kpiGrade = UserKpiGrade.builder()
                .snapshot(snapshot)
                .benchmark(benchmark)
                .engagementRateGrade(engGrade)
                .viewVelocityGrade(velGrade)
                .followerGrowthGrade(growGrade)
                .watchTimeGrade(watchGrade)
                .shareRateGrade(shareGrade)
                .overallGrade(overall)
                .build();

        return gradeRepo.save(kpiGrade);
    }

    // ── KPI computation helpers ───────────────────────────────────────────────

    /**
     * Engagement Rate = (likes + comments + shares) / views
     */
    public static double computeEngagementRate(long likes, long comments, long shares, long views) {
        if (views == 0) return 0.0;
        return (double) (likes + comments + shares) / views;
    }

    /**
     * View Velocity = (current views − previous views) / previous views * 100
     */
    public static double computeViewVelocity(long currentViews, long previousViews) {
        if (previousViews == 0) return 0.0;
        return ((double) (currentViews - previousViews) / previousViews) * 100.0;
    }

    /**
     * Follower Growth Rate = (current − previous) / previous * 100
     */
    public static double computeFollowerGrowthRate(long current, long previous) {
        if (previous == 0) return 0.0;
        return ((double) (current - previous) / previous) * 100.0;
    }

    /**
     * Share Rate = shares / views
     */
    public static double computeShareRate(long shares, long views) {
        if (views == 0) return 0.0;
        return (double) shares / views;
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private String grade(Double userValue, Double benchmarkValue) {
        if (userValue == null || benchmarkValue == null || benchmarkValue == 0) return "C";
        double ratio = userValue / benchmarkValue;
        if (ratio >= 1.2) return "A";
        if (ratio >= 1.0) return "B";
        if (ratio >= 0.8) return "C";
        if (ratio >= 0.6) return "D";
        return "F";
    }

    // Watch time graded on absolute scale: A ≥ 75%, B ≥ 60%, C ≥ 45%, D ≥ 30%
    private String gradeWatch(Double pct) {
        if (pct == null) return "C";
        if (pct >= 75) return "A";
        if (pct >= 60) return "B";
        if (pct >= 45) return "C";
        if (pct >= 30) return "D";
        return "F";
    }

    private String overallGrade(String... grades) {
        double avg = 0;
        for (String g : grades) avg += gradeToNum(g);
        avg /= grades.length;
        if (avg >= 4.5) return "A";
        if (avg >= 3.5) return "B";
        if (avg >= 2.5) return "C";
        if (avg >= 1.5) return "D";
        return "F";
    }

    private int gradeToNum(String g) {
        return switch (g) { case "A" -> 5; case "B" -> 4; case "C" -> 3; case "D" -> 2; default -> 1; };
    }

    private KpiGradeResponse getLatestGrades(UUID snapshotId) {
        return gradeRepo.findBySnapshotId(snapshotId)
                .map(g -> KpiGradeResponse.builder()
                        .engagementRate(g.getEngagementRateGrade())
                        .viewVelocity(g.getViewVelocityGrade())
                        .followerGrowth(g.getFollowerGrowthGrade())
                        .watchTime(g.getWatchTimeGrade())
                        .shareRate(g.getShareRateGrade())
                        .overall(g.getOverallGrade())
                        .build())
                .orElse(null);
    }

    private PerformanceSnapshotResponse toSnapshotDto(UserPerformanceSnapshot s) {
        return PerformanceSnapshotResponse.builder()
                .periodStart(s.getPeriodStart())
                .periodEnd(s.getPeriodEnd())
                .engagementRate(s.getEngagementRate())
                .viewVelocity(s.getViewVelocity())
                .followerGrowthRate(s.getFollowerGrowthRate())
                .avgWatchTimePct(s.getAvgWatchTimePct())
                .shareRate(s.getShareRate())
                .followerCount(s.getFollowerCount())
                .totalViews(s.getTotalViews())
                .build();
    }

    private PerformanceSnapshotResponse toBenchmarkDto(TrendBenchmark b) {
        return PerformanceSnapshotResponse.builder()
                .periodStart(b.getPeriodStart())
                .periodEnd(b.getPeriodEnd())
                .engagementRate(b.getAvgEngagementRate())
                .viewVelocity(b.getAvgViewVelocity())
                .followerGrowthRate(b.getAvgFollowerGrowth())
                .shareRate(b.getAvgShareRate())
                .build();
    }
}
