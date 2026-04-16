package com.tiktoktrends.controller;

import com.tiktoktrends.dto.response.*;
import com.tiktoktrends.service.impl.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

// ─── Trends Controller ────────────────────────────────────────────────────────
@RestController
@RequestMapping("/api/v1/trends")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
class TrendsController {

    private final TrendService trendService;

    @GetMapping
    public ResponseEntity<List<TrendResponse>> getAllTrends() {
        return ResponseEntity.ok(trendService.getActiveTrends());
    }

    @GetMapping("/music")
    public ResponseEntity<List<TrendResponse>> getMusicTrends() {
        return ResponseEntity.ok(trendService.getTrendsByType("music"));
    }

    @GetMapping("/hashtags")
    public ResponseEntity<List<TrendResponse>> getHashtagTrends() {
        return ResponseEntity.ok(trendService.getTrendsByType("hashtag"));
    }

    @GetMapping("/categories")
    public ResponseEntity<List<TrendResponse>> getCategoryTrends() {
        return ResponseEntity.ok(trendService.getTrendsByType("content_category"));
    }

    @GetMapping("/top")
    public ResponseEntity<List<TrendResponse>> getTopTrends(
            @RequestParam(defaultValue = "hashtag") String type,
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(trendService.getTopTrends(type, limit));
    }

    /** Hashtags trending within a given content category (e.g. "Entertainment"). */
    @GetMapping("/categories/{category}/hashtags")
    public ResponseEntity<List<TrendResponse>> getCategoryHashtags(@PathVariable String category) {
        return ResponseEntity.ok(trendService.getHashtagsForCategory(category));
    }
}

// ─── Performance Analytics Controller ────────────────────────────────────────
@RestController
@RequestMapping("/api/v1/analytics")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
class PerformanceAnalyticsController {

    private final PerformanceAnalyticsService analyticsService;

    /**
     * Returns 6-month performance history + benchmark overlay + KPI grades.
     * This is what powers all three dashboard views (graph, overlay, scorecard).
     */
    @GetMapping("/performance")
    public ResponseEntity<PerformanceComparisonResponse> getPerformanceComparison(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        return ResponseEntity.ok(analyticsService.getPerformanceComparison(userId));
    }

    /**
     * AI explanation of why the user's top videos performed.
     * Demo-mode returns canned data; in prod this would call Claude with real video data.
     */
    @RequestMapping(value = "/video-analysis", method = {RequestMethod.GET, RequestMethod.POST})
    public ResponseEntity<VideoAnalysisResponse> getVideoAnalysis(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(buildDemoVideoAnalysis());
    }

    private static VideoAnalysisResponse buildDemoVideoAnalysis() {
        return VideoAnalysisResponse.builder()
            .id(UUID.randomUUID())
            .analyzedAt(java.time.LocalDateTime.now())
            .topVideos(java.util.List.of(
                VideoAnalysisResponse.VideoSummary.builder()
                    .videoId("demo-1").title("POV: Monday morning").viewCount(842_000L)
                    .engagementRate(0.187).thumbnailUrl(null).build(),
                VideoAnalysisResponse.VideoSummary.builder()
                    .videoId("demo-2").title("3 hacks for GRWM").viewCount(615_000L)
                    .engagementRate(0.162).thumbnailUrl(null).build(),
                VideoAnalysisResponse.VideoSummary.builder()
                    .videoId("demo-3").title("Storytime: my worst flight").viewCount(489_000L)
                    .engagementRate(0.155).thumbnailUrl(null).build()
            ))
            .analysis(
                "**Your top videos all share three things in common:**\n\n" +
                "1. They open with a *strong hook* in the first 1.5 seconds — usually a question or visual disruption.\n" +
                "2. They use **trending sounds** within 48 hours of those sounds breaking.\n" +
                "3. The captions are short (under 12 words) and end with a CTA like \"watch till the end\".\n\n" +
                "Your engagement rate (16.5% avg) is **65% above** your niche benchmark.")
            .keyTakeaways(java.util.List.of(
                "Hook in first 1.5s — open with a question or visual disruption",
                "Jump on trending sounds within 48 hours",
                "Keep captions under 12 words with a clear CTA",
                "Post Tue/Thu 6–8 PM for your audience"
            ))
            .build();
    }
}

// ─── Recommendations Controller ───────────────────────────────────────────────
@RestController
@RequestMapping("/api/v1/recommendations")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
class RecommendationsController {

    private final RecommendationService recommendationService;

    @PostMapping
    public ResponseEntity<RecommendationResponse> generateRecommendation(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        return ResponseEntity.ok(recommendationService.generateRecommendation(userId));
    }

    @GetMapping
    public ResponseEntity<List<RecommendationResponse>> getRecentRecommendations(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        return ResponseEntity.ok(recommendationService.getRecentRecommendations(userId));
    }
}

// ─── Ingestion Controller ────────────────────────────────────────────────────
@RestController
@RequestMapping("/api/v1/ingest")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
class IngestionController {

    private final com.tiktoktrends.scheduler.IngestionScheduler ingestionScheduler;

    @PostMapping("/trigger")
    public ResponseEntity<Map<String, String>> triggerIngestion() {
        ingestionScheduler.ingestPublicTrends();
        ingestionScheduler.snapshotUserPerformance();
        return ResponseEntity.ok(Map.of("status", "Ingestion triggered successfully"));
    }
}

// ─── Shared helper ────────────────────────────────────────────────────────────
class BaseController {
    static UUID extractUserId(UserDetails userDetails) {
        // UserDetails username stores the UUID in our JWT setup
        return UUID.fromString(userDetails.getUsername());
    }
}
