package com.tiktoktrends.repository;

import com.tiktoktrends.entity.Trend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TrendRepository extends JpaRepository<Trend, UUID> {

    List<Trend> findAllByOrderByVelocityScoreDesc();

    List<Trend> findByTrendTypeOrderByVelocityScoreDesc(String trendType);

    Optional<Trend> findByTrendTypeAndKeyword(String trendType, String keyword);

    @Query("SELECT t FROM Trend t WHERE t.expiresAt > :now ORDER BY t.velocityScore DESC")
    List<Trend> findActiveTrends(@Param("now") LocalDateTime now);

    @Query("SELECT t FROM Trend t WHERE t.trendType = :type AND t.expiresAt > :now ORDER BY t.velocityScore DESC LIMIT :limit")
    List<Trend> findTopActiveByType(@Param("type") String type,
                                    @Param("now") LocalDateTime now,
                                    @Param("limit") int limit);
}
