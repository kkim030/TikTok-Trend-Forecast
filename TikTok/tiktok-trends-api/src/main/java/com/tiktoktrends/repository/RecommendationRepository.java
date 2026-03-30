package com.tiktoktrends.repository;

import com.tiktoktrends.entity.Recommendation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RecommendationRepository extends JpaRepository<Recommendation, UUID> {
    List<Recommendation> findByUserIdOrderByGeneratedAtDesc(UUID userId);

    @Query("""
        SELECT r FROM Recommendation r
        WHERE r.user.id = :userId
        ORDER BY r.generatedAt DESC
        LIMIT 5
        """)
    List<Recommendation> findRecentByUserId(@Param("userId") UUID userId);
}
