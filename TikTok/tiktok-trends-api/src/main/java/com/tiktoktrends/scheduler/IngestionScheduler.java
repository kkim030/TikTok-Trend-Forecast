package com.tiktoktrends.scheduler;

import com.tiktoktrends.entity.*;
import com.tiktoktrends.repository.*;
import com.tiktoktrends.service.impl.PerformanceAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Runs every 2 hours (configurable via tiktok.ingestion.cron).
 *
 * Two jobs:
 *  1. ingestPublicTrends()  — fetches trending videos from TikTok Research API,
 *                             aggregates them into Trend records
 *  2. snapshotUserPerformance() — for every registered user, fetches their
 *                                 account stats and saves a weekly KPI snapshot
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IngestionScheduler {

    private final TrendRepository trendRepo;
    private final UserRepository userRepo;
    private final UserPerformanceSnapshotRepository snapshotRepo;
    private final TrendBenchmarkRepository benchmarkRepo;
    private final PerformanceAnalyticsService analyticsService;
    private final WebClient webClient;

    @Value("${tiktok.api.base-url}")    private String tiktokBaseUrl;
    @Value("${tiktok.api.client-key}")  private String clientKey;

    // ── Job 1: Public trend ingestion ─────────────────────────────────────────

    @Scheduled(cron = "${tiktok.ingestion.cron}")
    @CacheEvict(value = {"activeTrends", "trendsByType", "topTrends"}, allEntries = true)
    public void ingestPublicTrends() {
        log.info("Starting public trend ingestion run at {}", LocalDateTime.now());
        try {
            // Call TikTok Research API - query videos endpoint
            // Full implementation requires OAuth2 token exchange first.
            // Structure shown here; swap fetchRawVideos() with real API call.
            List<Map<String, Object>> rawVideos = fetchRawVideos();
            processTrends(rawVideos);
            computeBenchmarks();
            log.info("Trend ingestion complete. {} trends upserted.", trendRepo.count());
        } catch (Exception e) {
            log.error("Trend ingestion failed", e);
        }
    }

    // ── Job 2: Per-user performance snapshot ──────────────────────────────────

    @Scheduled(cron = "${tiktok.ingestion.cron}")
    @CacheEvict(value = "performanceComparison", allEntries = true)
    public void snapshotUserPerformance() {
        log.info("Snapshotting user performance at {}", LocalDateTime.now());
        List<User> users = userRepo.findAll();

        for (User user : users) {
            try {
                snapshotForUser(user);
            } catch (Exception e) {
                log.error("Snapshot failed for user {}: {}", user.getTiktokHandle(), e.getMessage());
            }
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Fetches trending video data from TikTok Research API.
     *
     * Endpoint: POST /v2/research/video/query/
     * Docs: https://developers.tiktok.com/doc/research-api-codebook-video
     *
     * TODO: Replace stub with real OAuth2 bearer token + API call:
     *   POST {tiktokBaseUrl}/research/video/query/
     *   Body: { "query": { "and": [{"operation":"GT","field_name":"video_duration","field_values":["5"]}] },
     *           "start_date": "20240101", "end_date": "20240107", "max_count": 100 }
     */
    private List<Map<String, Object>> fetchRawVideos() {
        // Stub — returns empty list until TikTok OAuth is wired up
        log.warn("TikTok API client not yet implemented — returning stub data");
        return Collections.emptyList();
    }

    /**
     * Aggregates raw video records into Trend entities.
     * Groups by hashtag, music, and content category.
     * Calculates velocity as avg engagement delta vs previous week.
     */
    private void processTrends(List<Map<String, Object>> videos) {
        // Hashtag aggregation
        Map<String, Long> hashtagCounts = new HashMap<>();
        Map<String, Double> hashtagEngagement = new HashMap<>();

        for (Map<String, Object> video : videos) {
            @SuppressWarnings("unchecked")
            List<String> hashtags = (List<String>) video.getOrDefault("hashtags", List.of());
            long views = ((Number) video.getOrDefault("views", 0)).longValue();
            long likes = ((Number) video.getOrDefault("likes", 0)).longValue();
            long comments = ((Number) video.getOrDefault("comments", 0)).longValue();
            long shares = ((Number) video.getOrDefault("shares", 0)).longValue();
            double er = PerformanceAnalyticsService.computeEngagementRate(likes, comments, shares, views);

            for (String tag : hashtags) {
                hashtagCounts.merge(tag, 1L, Long::sum);
                hashtagEngagement.merge(tag, er, Double::sum);
            }
        }

        // Upsert top hashtag trends
        hashtagCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(50)
                .forEach(entry -> {
                    String tag = entry.getKey();
                    double avgEr = hashtagEngagement.getOrDefault(tag, 0.0) / entry.getValue();

                    trendRepo.findByTrendTypeAndKeyword("hashtag", tag)
                            .ifPresentOrElse(
                                    existing -> {
                                        existing.setVelocityScore(computeVelocity(existing.getVelocityScore(), entry.getValue()));
                                        existing.setEngagementAvg(avgEr);
                                        existing.setExpiresAt(LocalDateTime.now().plusDays(3));
                                        trendRepo.save(existing);
                                    },
                                    () -> trendRepo.save(Trend.builder()
                                            .trendType("hashtag")
                                            .keyword(tag)
                                            .velocityScore((double) entry.getValue())
                                            .engagementAvg(avgEr)
                                            .expiresAt(LocalDateTime.now().plusDays(3))
                                            .build())
                            );
                });
    }

    /**
     * Computes platform-wide benchmark averages for the current week.
     * Stored in trend_benchmarks for comparison charts.
     */
    private void computeBenchmarks() {
        LocalDateTime weekStart = LocalDateTime.now().minusDays(7);
        LocalDateTime weekEnd   = LocalDateTime.now();

        // Pull averages from recently ingested trend data
        List<Trend> activeTrends = trendRepo.findActiveTrends(LocalDateTime.now());
        if (activeTrends.isEmpty()) return;

        double avgEngagement = activeTrends.stream()
                .mapToDouble(t -> t.getEngagementAvg() != null ? t.getEngagementAvg() : 0)
                .average().orElse(0);

        double avgVelocity = activeTrends.stream()
                .mapToDouble(t -> t.getVelocityScore() != null ? t.getVelocityScore() : 0)
                .average().orElse(0);

        TrendBenchmark benchmark = TrendBenchmark.builder()
                .periodStart(weekStart)
                .periodEnd(weekEnd)
                .avgEngagementRate(avgEngagement)
                .avgViewVelocity(avgVelocity)
                .avgShareRate(avgEngagement * 0.15)    // estimated ratio
                .avgFollowerGrowth(avgVelocity * 0.1)  // estimated ratio
                .build();

        benchmarkRepo.save(benchmark);
        log.info("Benchmark saved: engagementAvg={}, velocityAvg={}", avgEngagement, avgVelocity);
    }

    /**
     * Fetches a single user's account stats from TikTok and saves a snapshot.
     *
     * TODO: Wire up TikTok Research API user stats endpoint:
     *   GET /v2/research/user/info/?fields=display_name,bio_description,avatar_url,
     *         is_verified,follower_count,following_count,likes_count,video_count
     */
    private void snapshotForUser(User user) {
        // Retrieve previous snapshot for delta calculations
        Optional<UserPerformanceSnapshot> previous =
                snapshotRepo.findTopByUserIdOrderByRecordedAtDesc(user.getId());

        // === Replace this stub with real TikTok API user stats call ===
        long currentViews     = 0L;
        long currentFollowers = 0L;
        long currentLikes     = 0L;
        long currentShares    = 0L;
        long currentComments  = 0L;
        double watchTimePct   = 0.0;
        // ===============================================================

        double engagementRate = PerformanceAnalyticsService
                .computeEngagementRate(currentLikes, currentComments, currentShares, currentViews);

        double viewVelocity = previous
                .map(p -> PerformanceAnalyticsService.computeViewVelocity(currentViews, p.getTotalViews()))
                .orElse(0.0);

        double followerGrowth = previous
                .map(p -> PerformanceAnalyticsService.computeFollowerGrowthRate(currentFollowers, p.getFollowerCount()))
                .orElse(0.0);

        double shareRate = PerformanceAnalyticsService.computeShareRate(currentShares, currentViews);

        LocalDateTime now = LocalDateTime.now();
        UserPerformanceSnapshot snapshot = UserPerformanceSnapshot.builder()
                .user(user)
                .totalViews(currentViews)
                .totalLikes(currentLikes)
                .totalShares(currentShares)
                .totalComments(currentComments)
                .followerCount(currentFollowers)
                .engagementRate(engagementRate)
                .viewVelocity(viewVelocity)
                .followerGrowthRate(followerGrowth)
                .avgWatchTimePct(watchTimePct)
                .shareRate(shareRate)
                .periodStart(now.minusDays(7))
                .periodEnd(now)
                .build();

        UserPerformanceSnapshot saved = snapshotRepo.save(snapshot);

        // Auto-grade against latest benchmark
        benchmarkRepo.findTopByOrderByComputedAtDesc()
                .ifPresent(bench -> analyticsService.computeAndSaveGrades(saved, bench));

        log.info("Snapshot saved for @{}", user.getTiktokHandle());
    }

    private double computeVelocity(Double previousVelocity, long currentCount) {
        if (previousVelocity == null || previousVelocity == 0) return currentCount;
        return ((currentCount - previousVelocity) / previousVelocity) * 100.0;
    }
}
