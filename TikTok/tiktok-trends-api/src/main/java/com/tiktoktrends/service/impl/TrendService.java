package com.tiktoktrends.service.impl;

import com.tiktoktrends.dto.response.TrendResponse;
import com.tiktoktrends.entity.Trend;
import com.tiktoktrends.repository.TrendRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TrendService {

    private final TrendRepository trendRepository;

    @Cacheable("activeTrends")
    public List<TrendResponse> getActiveTrends() {
        return trendRepository.findActiveTrends(LocalDateTime.now())
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Cacheable(value = "trendsByType", key = "#type")
    public List<TrendResponse> getTrendsByType(String type) {
        return trendRepository.findByTrendTypeOrderByVelocityScoreDesc(type)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    @Cacheable(value = "topTrends", key = "#type + '-' + #limit")
    public List<TrendResponse> getTopTrends(String type, int limit) {
        return trendRepository.findTopActiveByType(type, LocalDateTime.now(), limit)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    /**
     * Returns hashtag trends associated with a content category.
     * Filters all hashtag trends by a static category→hashtags map (case-insensitive).
     */
    @Cacheable(value = "hashtagsByCategory", key = "#category")
    public List<TrendResponse> getHashtagsForCategory(String category) {
        List<String> keywords = CATEGORY_HASHTAGS.getOrDefault(category.toLowerCase(), List.of());
        if (keywords.isEmpty()) return List.of();
        return trendRepository.findByTrendTypeOrderByVelocityScoreDesc("hashtag")
                .stream()
                .filter(t -> keywords.contains(t.getKeyword().toLowerCase()))
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private static final Map<String, List<String>> CATEGORY_HASHTAGS = Map.of(
        "entertainment",   List.of("dancechallenge", "comedy", "pov", "storytime"),
        "lifestyle",       List.of("dayinmylife", "fitness", "getreadywithme"),
        "education",       List.of("booktok"),
        "food & cooking",  List.of("recipetok"),
        "fashion & beauty",List.of("ootd", "getreadywithme")
    );

    private TrendResponse toDto(Trend t) {
        return TrendResponse.builder()
                .id(t.getId())
                .trendType(t.getTrendType())
                .keyword(t.getKeyword())
                .velocityScore(t.getVelocityScore())
                .engagementAvg(t.getEngagementAvg())
                .viewCountAvg(t.getViewCountAvg())
                .detectedAt(t.getDetectedAt())
                .expiresAt(t.getExpiresAt())
                .build();
    }
}
