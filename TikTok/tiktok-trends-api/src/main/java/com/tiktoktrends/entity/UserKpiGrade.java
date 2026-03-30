package com.tiktoktrends.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_kpi_grades")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserKpiGrade {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "snapshot_id", nullable = false)
    private UserPerformanceSnapshot snapshot;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "benchmark_id", nullable = false)
    private TrendBenchmark benchmark;

    @Column(name = "engagement_rate_grade", length = 1) private String engagementRateGrade;
    @Column(name = "view_velocity_grade",   length = 1) private String viewVelocityGrade;
    @Column(name = "follower_growth_grade", length = 1) private String followerGrowthGrade;
    @Column(name = "watch_time_grade",      length = 1) private String watchTimeGrade;
    @Column(name = "share_rate_grade",      length = 1) private String shareRateGrade;
    @Column(name = "overall_grade",         length = 1) private String overallGrade;

    @Column(name = "graded_at") private LocalDateTime gradedAt = LocalDateTime.now();
}
