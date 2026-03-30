package com.tiktoktrends.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "trends")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Trend {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "trend_type", nullable = false)
    private String trendType;   // "hashtag" | "music" | "content_category"

    @Column(nullable = false)
    private String keyword;

    @Column(name = "velocity_score")
    private Double velocityScore;

    @Column(name = "engagement_avg")
    private Double engagementAvg;

    @Column(name = "view_count_avg")
    private Long viewCountAvg;

    @Column(name = "detected_at")
    private LocalDateTime detectedAt = LocalDateTime.now();

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;
}
