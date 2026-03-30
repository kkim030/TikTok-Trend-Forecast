package com.tiktoktrends.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "recommendations")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Recommendation {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trend_id")
    private Trend trend;

    @Column(name = "concept_title") private String conceptTitle;

    @Column(name = "concept_description", columnDefinition = "TEXT")
    private String conceptDescription;

    @Column(name = "suggested_music") private String suggestedMusic;

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "suggested_hashtags", columnDefinition = "TEXT[]")
    private List<String> suggestedHashtags;

    @Column(name = "confidence_score") private Double confidenceScore;

    @Column(name = "generated_at") private LocalDateTime generatedAt = LocalDateTime.now();
}
