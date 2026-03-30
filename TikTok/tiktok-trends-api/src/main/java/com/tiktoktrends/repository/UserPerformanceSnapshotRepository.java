package com.tiktoktrends.repository;

import com.tiktoktrends.entity.UserPerformanceSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserPerformanceSnapshotRepository extends JpaRepository<UserPerformanceSnapshot, UUID> {

    @Query("""
        SELECT s FROM UserPerformanceSnapshot s
        WHERE s.user.id = :userId AND s.periodStart >= :since
        ORDER BY s.periodStart ASC
        """)
    List<UserPerformanceSnapshot> findByUserIdSince(@Param("userId") UUID userId,
                                                    @Param("since") LocalDateTime since);

    Optional<UserPerformanceSnapshot> findTopByUserIdOrderByRecordedAtDesc(UUID userId);
}
