package com.tiktoktrends.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "user_performance_snapshots")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserPerformanceSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // Raw counts
    @Column(name = "total_views")   private Long totalViews;
    @Column(name = "total_likes")   private Long totalLikes;
    @Column(name = "total_shares")  private Long totalShares;
    @Column(name = "total_comments")private Long totalComments;
    @Column(name = "follower_count")private Long followerCount;
    @Column(name = "video_count")   private Integer videoCount;

    // Computed KPIs
    @Column(name = "engagement_rate")       private Double engagementRate;
    @Column(name = "view_velocity")         private Double viewVelocity;
    @Column(name = "follower_growth_rate")  private Double followerGrowthRate;
    @Column(name = "avg_watch_time_pct")    private Double avgWatchTimePct;
    @Column(name = "share_rate")            private Double shareRate;

    @Column(name = "period_start", nullable = false) private LocalDateTime periodStart;
    @Column(name = "period_end",   nullable = false) private LocalDateTime periodEnd;
    @Column(name = "recorded_at")           private LocalDateTime recordedAt = LocalDateTime.now();
}
