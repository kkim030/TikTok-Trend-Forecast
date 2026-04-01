package com.tiktoktrends.service.impl;

import com.tiktoktrends.dto.response.PerformanceComparisonResponse;
import com.tiktoktrends.entity.TrendBenchmark;
import com.tiktoktrends.entity.UserKpiGrade;
import com.tiktoktrends.entity.UserPerformanceSnapshot;
import com.tiktoktrends.repository.TrendBenchmarkRepository;
import com.tiktoktrends.repository.UserKpiGradeRepository;
import com.tiktoktrends.repository.UserPerformanceSnapshotRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PerformanceAnalyticsServiceTest {

    @Mock private UserPerformanceSnapshotRepository snapshotRepo;
    @Mock private TrendBenchmarkRepository benchmarkRepo;
    @Mock private UserKpiGradeRepository gradeRepo;

    @InjectMocks
    private PerformanceAnalyticsService service;

    // ── Static KPI computation tests ─────────────────────────────────────────

    @Test
    void computeEngagementRate_normalCase() {
        double er = PerformanceAnalyticsService.computeEngagementRate(100, 20, 10, 1000);
        assertThat(er).isEqualTo(0.13); // (100+20+10)/1000
    }

    @Test
    void computeEngagementRate_zeroViews() {
        double er = PerformanceAnalyticsService.computeEngagementRate(100, 20, 10, 0);
        assertThat(er).isEqualTo(0.0);
    }

    @Test
    void computeViewVelocity_normalGrowth() {
        double velocity = PerformanceAnalyticsService.computeViewVelocity(1500, 1000);
        assertThat(velocity).isEqualTo(50.0); // 50% growth
    }

    @Test
    void computeViewVelocity_zeroPrevious() {
        double velocity = PerformanceAnalyticsService.computeViewVelocity(1000, 0);
        assertThat(velocity).isEqualTo(0.0);
    }

    @Test
    void computeViewVelocity_decline() {
        double velocity = PerformanceAnalyticsService.computeViewVelocity(500, 1000);
        assertThat(velocity).isEqualTo(-50.0);
    }

    @Test
    void computeFollowerGrowthRate_normalGrowth() {
        double growth = PerformanceAnalyticsService.computeFollowerGrowthRate(1100, 1000);
        assertThat(growth).isEqualTo(10.0);
    }

    @Test
    void computeFollowerGrowthRate_zeroPrevious() {
        double growth = PerformanceAnalyticsService.computeFollowerGrowthRate(500, 0);
        assertThat(growth).isEqualTo(0.0);
    }

    @Test
    void computeShareRate_normalCase() {
        double sr = PerformanceAnalyticsService.computeShareRate(50, 1000);
        assertThat(sr).isEqualTo(0.05);
    }

    @Test
    void computeShareRate_zeroViews() {
        double sr = PerformanceAnalyticsService.computeShareRate(50, 0);
        assertThat(sr).isEqualTo(0.0);
    }

    // ── Grading tests ────────────────────────────────────────────────────────

    @Test
    void computeAndSaveGrades_highPerformer_getsAGrades() {
        UserPerformanceSnapshot snapshot = UserPerformanceSnapshot.builder()
                .engagementRate(0.24)     // 120% of benchmark → A
                .viewVelocity(60.0)       // 120% of benchmark → A
                .followerGrowthRate(12.0) // 120% of benchmark → A
                .avgWatchTimePct(80.0)    // ≥75 → A
                .shareRate(0.06)          // 120% of benchmark → A
                .build();

        TrendBenchmark benchmark = TrendBenchmark.builder()
                .avgEngagementRate(0.2)
                .avgViewVelocity(50.0)
                .avgFollowerGrowth(10.0)
                .avgShareRate(0.05)
                .build();

        ArgumentCaptor<UserKpiGrade> captor = ArgumentCaptor.forClass(UserKpiGrade.class);
        when(gradeRepo.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        service.computeAndSaveGrades(snapshot, benchmark);

        UserKpiGrade saved = captor.getValue();
        assertThat(saved.getEngagementRateGrade()).isEqualTo("A");
        assertThat(saved.getViewVelocityGrade()).isEqualTo("A");
        assertThat(saved.getFollowerGrowthGrade()).isEqualTo("A");
        assertThat(saved.getWatchTimeGrade()).isEqualTo("A");
        assertThat(saved.getShareRateGrade()).isEqualTo("A");
        assertThat(saved.getOverallGrade()).isEqualTo("A");
    }

    @Test
    void computeAndSaveGrades_lowPerformer_getsFGrades() {
        UserPerformanceSnapshot snapshot = UserPerformanceSnapshot.builder()
                .engagementRate(0.01)
                .viewVelocity(5.0)
                .followerGrowthRate(1.0)
                .avgWatchTimePct(10.0)
                .shareRate(0.005)
                .build();

        TrendBenchmark benchmark = TrendBenchmark.builder()
                .avgEngagementRate(0.2)
                .avgViewVelocity(50.0)
                .avgFollowerGrowth(10.0)
                .avgShareRate(0.05)
                .build();

        when(gradeRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UserKpiGrade result = service.computeAndSaveGrades(snapshot, benchmark);

        assertThat(result.getOverallGrade()).isEqualTo("F");
    }

    @Test
    void computeAndSaveGrades_averagePerformer_getsBGrades() {
        UserPerformanceSnapshot snapshot = UserPerformanceSnapshot.builder()
                .engagementRate(0.2)      // 100% → B
                .viewVelocity(50.0)       // 100% → B
                .followerGrowthRate(10.0) // 100% → B
                .avgWatchTimePct(65.0)    // ≥60 → B
                .shareRate(0.05)          // 100% → B
                .build();

        TrendBenchmark benchmark = TrendBenchmark.builder()
                .avgEngagementRate(0.2)
                .avgViewVelocity(50.0)
                .avgFollowerGrowth(10.0)
                .avgShareRate(0.05)
                .build();

        when(gradeRepo.save(any())).thenAnswer(inv -> inv.getArgument(0));

        UserKpiGrade result = service.computeAndSaveGrades(snapshot, benchmark);

        assertThat(result.getOverallGrade()).isEqualTo("B");
    }

    // ── getPerformanceComparison tests ───────────────────────────────────────

    @Test
    void getPerformanceComparison_returnsEmptyWhenNoData() {
        UUID userId = UUID.randomUUID();
        when(snapshotRepo.findByUserIdSince(eq(userId), any())).thenReturn(List.of());
        when(benchmarkRepo.findBenchmarksSince(any())).thenReturn(List.of());

        PerformanceComparisonResponse response = service.getPerformanceComparison(userId);

        assertThat(response.getUserSnapshots()).isEmpty();
        assertThat(response.getBenchmarks()).isEmpty();
        assertThat(response.getCurrentGrades()).isNull();
    }

    @Test
    void getPerformanceComparison_mapsSnapshotsAndBenchmarks() {
        UUID userId = UUID.randomUUID();
        LocalDateTime now = LocalDateTime.now();

        UserPerformanceSnapshot snapshot = UserPerformanceSnapshot.builder()
                .id(UUID.randomUUID())
                .engagementRate(0.15)
                .viewVelocity(30.0)
                .followerGrowthRate(5.0)
                .avgWatchTimePct(55.0)
                .shareRate(0.03)
                .followerCount(10000L)
                .totalViews(500000L)
                .periodStart(now.minusDays(7))
                .periodEnd(now)
                .build();

        TrendBenchmark benchmark = TrendBenchmark.builder()
                .avgEngagementRate(0.12)
                .avgViewVelocity(25.0)
                .avgFollowerGrowth(4.0)
                .avgShareRate(0.02)
                .periodStart(now.minusDays(7))
                .periodEnd(now)
                .build();

        when(snapshotRepo.findByUserIdSince(eq(userId), any())).thenReturn(List.of(snapshot));
        when(benchmarkRepo.findBenchmarksSince(any())).thenReturn(List.of(benchmark));
        when(gradeRepo.findBySnapshotId(snapshot.getId())).thenReturn(Optional.empty());

        PerformanceComparisonResponse response = service.getPerformanceComparison(userId);

        assertThat(response.getUserSnapshots()).hasSize(1);
        assertThat(response.getBenchmarks()).hasSize(1);
        assertThat(response.getUserSnapshots().get(0).getEngagementRate()).isEqualTo(0.15);
        assertThat(response.getBenchmarks().get(0).getEngagementRate()).isEqualTo(0.12);
    }
}
