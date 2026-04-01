package com.tiktoktrends.service.impl;

import com.tiktoktrends.dto.response.TrendResponse;
import com.tiktoktrends.entity.Trend;
import com.tiktoktrends.repository.TrendRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TrendServiceTest {

    @Mock
    private TrendRepository trendRepository;

    @InjectMocks
    private TrendService trendService;

    private Trend sampleTrend;

    @BeforeEach
    void setUp() {
        sampleTrend = Trend.builder()
                .id(UUID.randomUUID())
                .trendType("hashtag")
                .keyword("dance")
                .velocityScore(85.5)
                .engagementAvg(0.12)
                .viewCountAvg(50000L)
                .detectedAt(LocalDateTime.now())
                .expiresAt(LocalDateTime.now().plusDays(3))
                .build();
    }

    @Test
    void getActiveTrends_returnsMappedDtos() {
        when(trendRepository.findActiveTrends(any(LocalDateTime.class)))
                .thenReturn(List.of(sampleTrend));

        List<TrendResponse> result = trendService.getActiveTrends();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getKeyword()).isEqualTo("dance");
        assertThat(result.get(0).getTrendType()).isEqualTo("hashtag");
        assertThat(result.get(0).getVelocityScore()).isEqualTo(85.5);
    }

    @Test
    void getActiveTrends_emptyList() {
        when(trendRepository.findActiveTrends(any(LocalDateTime.class)))
                .thenReturn(List.of());

        List<TrendResponse> result = trendService.getActiveTrends();

        assertThat(result).isEmpty();
    }

    @Test
    void getTrendsByType_filtersCorrectly() {
        when(trendRepository.findByTrendTypeOrderByVelocityScoreDesc("music"))
                .thenReturn(List.of(sampleTrend));

        List<TrendResponse> result = trendService.getTrendsByType("music");

        assertThat(result).hasSize(1);
    }

    @Test
    void getTopTrends_respectsLimitAndType() {
        Trend trend2 = Trend.builder()
                .id(UUID.randomUUID())
                .trendType("hashtag")
                .keyword("comedy")
                .velocityScore(70.0)
                .engagementAvg(0.08)
                .expiresAt(LocalDateTime.now().plusDays(3))
                .build();

        when(trendRepository.findTopActiveByType(eq("hashtag"), any(LocalDateTime.class), eq(2)))
                .thenReturn(List.of(sampleTrend, trend2));

        List<TrendResponse> result = trendService.getTopTrends("hashtag", 2);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getKeyword()).isEqualTo("dance");
        assertThat(result.get(1).getKeyword()).isEqualTo("comedy");
    }

    @Test
    void getActiveTrends_mapsAllFields() {
        when(trendRepository.findActiveTrends(any(LocalDateTime.class)))
                .thenReturn(List.of(sampleTrend));

        TrendResponse dto = trendService.getActiveTrends().get(0);

        assertThat(dto.getId()).isEqualTo(sampleTrend.getId());
        assertThat(dto.getTrendType()).isEqualTo(sampleTrend.getTrendType());
        assertThat(dto.getKeyword()).isEqualTo(sampleTrend.getKeyword());
        assertThat(dto.getVelocityScore()).isEqualTo(sampleTrend.getVelocityScore());
        assertThat(dto.getEngagementAvg()).isEqualTo(sampleTrend.getEngagementAvg());
        assertThat(dto.getViewCountAvg()).isEqualTo(sampleTrend.getViewCountAvg());
        assertThat(dto.getDetectedAt()).isEqualTo(sampleTrend.getDetectedAt());
        assertThat(dto.getExpiresAt()).isEqualTo(sampleTrend.getExpiresAt());
    }
}
