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
