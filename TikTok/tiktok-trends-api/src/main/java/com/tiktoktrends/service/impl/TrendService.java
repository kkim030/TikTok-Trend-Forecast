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
