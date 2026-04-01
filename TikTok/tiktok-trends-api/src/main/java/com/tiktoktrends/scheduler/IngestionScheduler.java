package com.tiktoktrends.scheduler;

import com.tiktoktrends.entity.*;
import com.tiktoktrends.repository.*;
import com.tiktoktrends.service.impl.PerformanceAnalyticsService;
import com.tiktoktrends.service.impl.TikTokOAuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.util.retry.Retry;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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
    private final TikTokOAuthService oAuthService;
    private final WebClient webClient;

    @Value("${tiktok.api.base-url}")    private String tiktokBaseUrl;
    @Value("${tiktok.api.client-key}")  private String clientKey;
    @Value("${tiktok.api.client-secret}") private String clientSecret;

    private static final int MAX_VIDEO_COUNT = 100;
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    // ── Job 1: Public trend ingestion ─────────────────────────────────────────

    @Scheduled(cron = "${tiktok.ingestion.cron}")
    @CacheEvict(value = {"activeTrends", "trendsByType", "topTrends"}, allEntries = true)
    public void ingestPublicTrends() {
        log.info("Starting public trend ingestion run at {}", LocalDateTime.now());
        try {
            String accessToken = getClientAccessToken();
            List<Map<String, Object>> rawVideos = fetchRawVideos(accessToken);
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
                oAuthService.refreshTokenIfNeeded(user);
                snapshotForUser(user);
            } catch (Exception e) {
                log.error("Snapshot failed for user {}: {}", user.getTiktokHandle(), e.getMessage());
            }
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    /**
     * Obtains a client access token via OAuth2 client credentials flow.
     * Used for Research API endpoints that don't require user authorization.
     */
    @SuppressWarnings("unchecked")
    private String getClientAccessToken() {
        Map<String, Object> body = Map.of(
                "client_key", clientKey,
                "client_secret", clientSecret,
                "grant_type", "client_credentials"
        );

        Map<String, Object> response = webClient.post()
                .uri("https://open.tiktokapis.com/v2/oauth/token/")
                .header("Content-Type", "application/json")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(Map.class)
                .retryWhen(rateLimitRetry())
                .block();

        if (response == null || !response.containsKey("access_token")) {
            throw new RuntimeException("Failed to obtain TikTok client access token: " + response);
        }

        return (String) response.get("access_token");
    }

    /**
     * Fetches trending video data from TikTok Research API.
     *
     * Endpoint: POST /v2/research/video/query/
     * Queries videos from the past 7 days with > 5 second duration.
     */
    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> fetchRawVideos(String accessToken) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(7);

        Map<String, Object> query = Map.of(
                "and", List.of(
                        Map.of("operation", "GT", "field_name", "video_duration", "field_values", List.of("5"))
                )
        );

        Map<String, Object> requestBody = Map.of(
                "query", query,
                "start_date", startDate.format(DATE_FMT),
                "end_date", endDate.format(DATE_FMT),
                "max_count", MAX_VIDEO_COUNT
        );

        Map<String, Object> response = webClient.post()
                .uri(tiktokBaseUrl + "/research/video/query/")
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .retryWhen(rateLimitRetry())
                .block();

        if (response == null || !response.containsKey("data")) {
            log.warn("TikTok Research API returned no data: {}", response);
            return Collections.emptyList();
        }

        Map<String, Object> data = (Map<String, Object>) response.get("data");
        List<Map<String, Object>> videos = (List<Map<String, Object>>) data.get("videos");
        return videos != null ? videos : Collections.emptyList();
    }

    /**
     * Aggregates raw video records into Trend entities.
     * Groups by hashtag, music, and content category.
     * Includes deduplication — skips videos whose IDs have already been counted
     * in the current ingestion window.
     */
    private void processTrends(List<Map<String, Object>> videos) {
        // Deduplication: track video IDs seen in this batch
        Set<String> seenVideoIds = new HashSet<>();

        Map<String, Long> hashtagCounts = new HashMap<>();
        Map<String, Double> hashtagEngagement = new HashMap<>();
        Map<String, Long> hashtagViews = new HashMap<>();

        Map<String, Long> musicCounts = new HashMap<>();
        Map<String, Double> musicEngagement = new HashMap<>();

        for (Map<String, Object> video : videos) {
            // Deduplicate by video ID
            String videoId = String.valueOf(video.getOrDefault("id", ""));
            if (videoId.isEmpty() || !seenVideoIds.add(videoId)) {
                continue;
            }

            long views = numberToLong(video.getOrDefault("view_count", video.getOrDefault("views", 0)));
            long likes = numberToLong(video.getOrDefault("like_count", video.getOrDefault("likes", 0)));
            long comments = numberToLong(video.getOrDefault("comment_count", video.getOrDefault("comments", 0)));
            long shares = numberToLong(video.getOrDefault("share_count", video.getOrDefault("shares", 0)));
            double er = PerformanceAnalyticsService.computeEngagementRate(likes, comments, shares, views);

            // Hashtag aggregation
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> hashtags = (List<Map<String, Object>>) video.getOrDefault("hashtag_names",
                    video.getOrDefault("hashtags", List.of()));
            List<String> tagNames = extractStringList(hashtags, video);

            for (String tag : tagNames) {
                String normalizedTag = tag.toLowerCase().trim();
                if (normalizedTag.isEmpty()) continue;
                hashtagCounts.merge(normalizedTag, 1L, Long::sum);
                hashtagEngagement.merge(normalizedTag, er, Double::sum);
                hashtagViews.merge(normalizedTag, views, Long::sum);
            }

            // Music aggregation
            String music = (String) video.getOrDefault("music_id",
                    video.getOrDefault("music", null));
            if (music != null && !music.isBlank()) {
                musicCounts.merge(music, 1L, Long::sum);
                musicEngagement.merge(music, er, Double::sum);
            }
        }

        log.info("Processed {} unique videos ({} duplicates skipped)",
                seenVideoIds.size(), videos.size() - seenVideoIds.size());

        // Upsert top hashtag trends
        upsertTrends(hashtagCounts, hashtagEngagement, hashtagViews, "hashtag");

        // Upsert top music trends
        upsertTrends(musicCounts, musicEngagement, new HashMap<>(), "music");
    }

    private void upsertTrends(Map<String, Long> counts, Map<String, Double> engagement,
                              Map<String, Long> views, String trendType) {
        counts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .limit(50)
                .forEach(entry -> {
                    String keyword = entry.getKey();
                    double avgEr = engagement.getOrDefault(keyword, 0.0) / entry.getValue();
                    Long avgViews = views.isEmpty() ? null :
                            views.getOrDefault(keyword, 0L) / entry.getValue();

                    trendRepo.findByTrendTypeAndKeyword(trendType, keyword)
                            .ifPresentOrElse(
                                    existing -> {
                                        existing.setVelocityScore(computeVelocity(existing.getVelocityScore(), entry.getValue()));
                                        existing.setEngagementAvg(avgEr);
                                        existing.setViewCountAvg(avgViews);
                                        existing.setExpiresAt(LocalDateTime.now().plusDays(3));
                                        trendRepo.save(existing);
                                    },
                                    () -> trendRepo.save(Trend.builder()
                                            .trendType(trendType)
                                            .keyword(keyword)
                                            .velocityScore((double) entry.getValue())
                                            .engagementAvg(avgEr)
                                            .viewCountAvg(avgViews)
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
                .avgShareRate(avgEngagement * 0.15)
                .avgFollowerGrowth(avgVelocity * 0.1)
                .build();

        benchmarkRepo.save(benchmark);
        log.info("Benchmark saved: engagementAvg={}, velocityAvg={}", avgEngagement, avgVelocity);
    }

    /**
     * Fetches a single user's account stats from TikTok and saves a snapshot.
     *
     * Endpoint: GET /v2/research/user/info/
     * Fields: follower_count, following_count, likes_count, video_count
     */
    @SuppressWarnings("unchecked")
    private void snapshotForUser(User user) {
        if (user.getTiktokAccessToken() == null) {
            log.warn("Skipping snapshot for @{} — no access token", user.getTiktokHandle());
            return;
        }

        Optional<UserPerformanceSnapshot> previous =
                snapshotRepo.findTopByUserIdOrderByRecordedAtDesc(user.getId());

        // Fetch real user stats from TikTok API
        Map<String, Object> response = webClient.get()
                .uri(tiktokBaseUrl + "/user/info/?fields=follower_count,following_count,likes_count,video_count")
                .header("Authorization", "Bearer " + user.getTiktokAccessToken())
                .retrieve()
                .bodyToMono(Map.class)
                .retryWhen(rateLimitRetry())
                .block();

        if (response == null || !response.containsKey("data")) {
            log.warn("No user stats returned for @{}", user.getTiktokHandle());
            return;
        }

        Map<String, Object> data = (Map<String, Object>) response.get("data");
        Map<String, Object> userInfo = (Map<String, Object>) data.get("user");

        long currentFollowers = numberToLong(userInfo.getOrDefault("follower_count", 0));
        long currentLikes     = numberToLong(userInfo.getOrDefault("likes_count", 0));
        long currentViews     = numberToLong(userInfo.getOrDefault("video_count", 0)) * 500L; // estimated
        long currentShares    = (long) (currentLikes * 0.05); // estimated from likes
        long currentComments  = (long) (currentLikes * 0.1);  // estimated from likes
        double watchTimePct   = 0.0; // not available via this endpoint

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

    /**
     * Retry strategy for TikTok API rate limits (HTTP 429).
     * Exponential backoff: 2s, 4s, 8s — max 3 retries.
     */
    private Retry rateLimitRetry() {
        return Retry.backoff(3, Duration.ofSeconds(2))
                .filter(throwable -> {
                    if (throwable instanceof WebClientResponseException ex) {
                        return ex.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS;
                    }
                    return false;
                })
                .doBeforeRetry(signal ->
                        log.warn("TikTok API rate limited, retry #{} after backoff", signal.totalRetries() + 1));
    }

    private double computeVelocity(Double previousVelocity, long currentCount) {
        if (previousVelocity == null || previousVelocity == 0) return currentCount;
        return ((currentCount - previousVelocity) / previousVelocity) * 100.0;
    }

    private long numberToLong(Object value) {
        if (value instanceof Number n) return n.longValue();
        try { return Long.parseLong(String.valueOf(value)); }
        catch (NumberFormatException e) { return 0L; }
    }

    /**
     * Extracts hashtag names from TikTok API response.
     * Handles both List<String> and List<Map> formats.
     */
    @SuppressWarnings("unchecked")
    private List<String> extractStringList(Object hashtags, Map<String, Object> video) {
        if (hashtags instanceof List<?> list) {
            if (list.isEmpty()) return List.of();
            if (list.get(0) instanceof String) return (List<String>) list;
            if (list.get(0) instanceof Map) {
                return list.stream()
                        .map(item -> (String) ((Map<String, Object>) item).getOrDefault("hashtag_name",
                                ((Map<String, Object>) item).getOrDefault("name", "")))
                        .filter(name -> !name.isEmpty())
                        .toList();
            }
        }
        return List.of();
    }
}
