package com.tiktoktrends.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "trend_benchmarks")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TrendBenchmark {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "period_start", nullable = false) private LocalDateTime periodStart;
    @Column(name = "period_end",   nullable = false) private LocalDateTime periodEnd;

    @Column(name = "avg_engagement_rate") private Double avgEngagementRate;
    @Column(name = "avg_view_velocity")   private Double avgViewVelocity;
    @Column(name = "avg_share_rate")      private Double avgShareRate;
    @Column(name = "avg_follower_growth") private Double avgFollowerGrowth;

    @Column(name = "computed_at") private LocalDateTime computedAt = LocalDateTime.now();
}
