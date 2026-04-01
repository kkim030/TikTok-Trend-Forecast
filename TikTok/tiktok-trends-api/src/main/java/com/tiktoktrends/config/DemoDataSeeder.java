package com.tiktoktrends.config;

import com.tiktoktrends.entity.*;
import com.tiktoktrends.repository.*;
import com.tiktoktrends.service.impl.PerformanceAnalyticsService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Component
@Profile("demo")
@RequiredArgsConstructor
public class DemoDataSeeder implements CommandLineRunner {

    private final UserRepository userRepo;
    private final TrendRepository trendRepo;
    private final TrendBenchmarkRepository benchmarkRepo;
    private final UserPerformanceSnapshotRepository snapshotRepo;
    private final RecommendationRepository recommendationRepo;
    private final PerformanceAnalyticsService analyticsService;

    @Override
    public void run(String... args) {
        if (trendRepo.count() > 0) {
            log.info("Demo data already exists — skipping seed.");
            return;
        }

        log.info("Seeding demo data...");

        // ── Demo user ────────────────────────────────────────────
        User demoUser = userRepo.save(User.builder()
                .tiktokHandle("demo_creator")
                .displayName("Demo Creator")
                .niche("comedy")
                .build());

        // ── Trends ───────────────────────────────────────────────
        List<Trend> trends = trendRepo.saveAll(List.of(
                trend("hashtag", "dancechallenge", 92.5, 0.18, 1200000L),
                trend("hashtag", "storytime", 85.3, 0.15, 980000L),
                trend("hashtag", "getreadywithme", 78.1, 0.14, 870000L),
                trend("hashtag", "comedy", 74.6, 0.12, 750000L),
                trend("hashtag", "dayinmylife", 71.2, 0.11, 620000L),
                trend("hashtag", "booktok", 68.0, 0.13, 540000L),
                trend("hashtag", "recipetok", 64.5, 0.10, 480000L),
                trend("hashtag", "fitness", 61.8, 0.09, 420000L),
                trend("hashtag", "ootd", 58.3, 0.08, 380000L),
                trend("hashtag", "pov", 55.0, 0.11, 350000L),
                trend("music", "Original Sound - viralbeats", 88.7, 0.16, 1100000L),
                trend("music", "Espresso - Sabrina Carpenter", 82.4, 0.14, 950000L),
                trend("music", "APT. - ROSE & Bruno Mars", 76.9, 0.13, 830000L),
                trend("music", "Birds of a Feather - Billie Eilish", 70.1, 0.12, 710000L),
                trend("music", "A Bar Song (Tipsy) - Shaboozey", 65.3, 0.10, 600000L),
                trend("content_category", "Entertainment", 90.0, 0.17, 1500000L),
                trend("content_category", "Lifestyle", 80.2, 0.13, 1100000L),
                trend("content_category", "Education", 72.5, 0.11, 800000L),
                trend("content_category", "Food & Cooking", 66.0, 0.10, 650000L),
                trend("content_category", "Fashion & Beauty", 60.8, 0.09, 500000L)
        ));

        // ── Benchmarks (6 months of weekly data) ─────────────────
        LocalDateTime now = LocalDateTime.now();
        for (int week = 24; week >= 0; week--) {
            LocalDateTime weekEnd = now.minusWeeks(week);
            LocalDateTime weekStart = weekEnd.minusDays(7);
            double drift = 1.0 + (24 - week) * 0.008;

            TrendBenchmark benchmark = benchmarkRepo.save(TrendBenchmark.builder()
                    .periodStart(weekStart)
                    .periodEnd(weekEnd)
                    .avgEngagementRate(0.10 * drift)
                    .avgViewVelocity(25.0 * drift)
                    .avgShareRate(0.015 * drift)
                    .avgFollowerGrowth(3.5 * drift)
                    .build());

            // ── User performance snapshots ───────────────────────
            double userDrift = 1.0 + (24 - week) * 0.012;
            double jitter = 0.9 + Math.random() * 0.2;

            double engRate = 0.13 * userDrift * jitter;
            double viewVel = 32.0 * userDrift * jitter;
            double follGrowth = 5.2 * userDrift * jitter;
            double watchTime = 52.0 + (24 - week) * 0.8 + (Math.random() * 6 - 3);
            double shareRate = 0.022 * userDrift * jitter;

            long totalViews = (long) (500000 * userDrift * jitter);
            long totalLikes = (long) (totalViews * engRate * 0.7);
            long totalShares = (long) (totalViews * shareRate);
            long totalComments = (long) (totalViews * engRate * 0.2);
            long followers = (long) (45000 * userDrift * jitter);

            UserPerformanceSnapshot snapshot = snapshotRepo.save(UserPerformanceSnapshot.builder()
                    .user(demoUser)
                    .totalViews(totalViews)
                    .totalLikes(totalLikes)
                    .totalShares(totalShares)
                    .totalComments(totalComments)
                    .followerCount(followers)
                    .engagementRate(engRate)
                    .viewVelocity(viewVel)
                    .followerGrowthRate(follGrowth)
                    .avgWatchTimePct(watchTime)
                    .shareRate(shareRate)
                    .periodStart(weekStart)
                    .periodEnd(weekEnd)
                    .build());

            analyticsService.computeAndSaveGrades(snapshot, benchmark);
        }

        // ── Recommendations ──────────────────────────────────────
        Trend topTrend = trends.get(0);
        recommendationRepo.saveAll(List.of(
                Recommendation.builder()
                        .user(demoUser).trend(topTrend)
                        .conceptTitle("POV: You Try the Viral Dance but Make It Comedy")
                        .conceptDescription("Film yourself attempting the trending dance challenge but intentionally mess up each move. Add text overlays rating your own performance. End with a slow-mo replay of your worst move.")
                        .suggestedMusic("Original Sound - viralbeats")
                        .suggestedHashtags(List.of("#dancechallenge", "#comedy", "#fail", "#fyp", "#viral"))
                        .confidenceScore(0.94)
                        .generatedAt(now.minusHours(2))
                        .build(),
                Recommendation.builder()
                        .user(demoUser).trend(trends.get(1))
                        .conceptTitle("Storytime: My Worst Day at Work (Animated)")
                        .conceptDescription("Use the green screen effect to tell a wild work story. Add animated stickers and sound effects at key moments. Keep it under 60 seconds with a plot twist ending.")
                        .suggestedMusic("Espresso - Sabrina Carpenter")
                        .suggestedHashtags(List.of("#storytime", "#work", "#comedy", "#relatable", "#fyp"))
                        .confidenceScore(0.89)
                        .generatedAt(now.minusDays(1))
                        .build(),
                Recommendation.builder()
                        .user(demoUser).trend(trends.get(2))
                        .conceptTitle("GRWM for a Job Interview at a Clown School")
                        .conceptDescription("Do a get-ready-with-me but your outfit gets progressively more absurd. Start normal, end in full clown makeup. Play it completely straight the whole time.")
                        .suggestedMusic("APT. - ROSE & Bruno Mars")
                        .suggestedHashtags(List.of("#getreadywithme", "#grwm", "#comedy", "#clown", "#fyp"))
                        .confidenceScore(0.85)
                        .generatedAt(now.minusDays(3))
                        .build()
        ));

        log.info("Demo data seeded: {} trends, 25 weekly snapshots, 3 recommendations", trends.size());
    }

    private Trend trend(String type, String keyword, double velocity, double engagement, long views) {
        return Trend.builder()
                .trendType(type)
                .keyword(keyword)
                .velocityScore(velocity)
                .engagementAvg(engagement)
                .viewCountAvg(views)
                .expiresAt(LocalDateTime.now().plusDays(3))
                .build();
    }
}
