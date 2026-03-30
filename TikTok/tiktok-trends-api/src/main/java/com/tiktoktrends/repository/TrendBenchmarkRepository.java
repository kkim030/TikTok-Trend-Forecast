package com.tiktoktrends.repository;

import com.tiktoktrends.entity.TrendBenchmark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TrendBenchmarkRepository extends JpaRepository<TrendBenchmark, UUID> {

    @Query("SELECT b FROM TrendBenchmark b WHERE b.periodStart >= :since ORDER BY b.periodStart ASC")
    List<TrendBenchmark> findBenchmarksSince(@Param("since") LocalDateTime since);

    Optional<TrendBenchmark> findTopByOrderByComputedAtDesc();
}
