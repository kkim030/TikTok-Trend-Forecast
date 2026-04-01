package com.tiktoktrends.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.tiktoktrends.dto.response.RecommendationResponse;
import com.tiktoktrends.entity.Recommendation;
import com.tiktoktrends.entity.Trend;
import com.tiktoktrends.entity.User;
import com.tiktoktrends.repository.RecommendationRepository;
import com.tiktoktrends.repository.TrendRepository;
import com.tiktoktrends.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RecommendationServiceTest {

    @Mock private RecommendationRepository recommendationRepo;
    @Mock private TrendRepository trendRepo;
    @Mock private UserRepository userRepo;
    @Mock private WebClient webClient;

    private ObjectMapper objectMapper;

    @InjectMocks
    private RecommendationService service;

    private UUID userId;
    private User user;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());

        userId = UUID.randomUUID();
        user = User.builder()
                .id(userId)
                .tiktokHandle("testcreator")
                .niche("comedy")
                .build();
    }

    @Test
    void getRecentRecommendations_returnsMappedDtos() {
        Recommendation rec = Recommendation.builder()
                .id(UUID.randomUUID())
                .user(user)
                .conceptTitle("Dance Challenge Remix")
                .conceptDescription("Film a 15-second dance to trending audio")
                .suggestedMusic("Original Sound - viralbeats")
                .suggestedHashtags(List.of("#dance", "#viral", "#fyp"))
                .confidenceScore(0.92)
                .generatedAt(LocalDateTime.now())
                .build();

        when(recommendationRepo.findRecentByUserId(userId)).thenReturn(List.of(rec));

        List<RecommendationResponse> result = service.getRecentRecommendations(userId);

        assertThat(result).hasSize(1);
        RecommendationResponse dto = result.get(0);
        assertThat(dto.getConceptTitle()).isEqualTo("Dance Challenge Remix");
        assertThat(dto.getConceptDescription()).isEqualTo("Film a 15-second dance to trending audio");
        assertThat(dto.getSuggestedMusic()).isEqualTo("Original Sound - viralbeats");
        assertThat(dto.getSuggestedHashtags()).containsExactly("#dance", "#viral", "#fyp");
        assertThat(dto.getConfidenceScore()).isEqualTo(0.92);
    }

    @Test
    void getRecentRecommendations_emptyList() {
        when(recommendationRepo.findRecentByUserId(userId)).thenReturn(List.of());

        List<RecommendationResponse> result = service.getRecentRecommendations(userId);

        assertThat(result).isEmpty();
    }

    @Test
    void generateRecommendation_userNotFound_throws() {
        UUID unknownId = UUID.randomUUID();
        when(userRepo.findById(unknownId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.generateRecommendation(unknownId))
                .hasMessageContaining("User not found");
    }

    @Test
    void getRecentRecommendations_multipleResults_preservesOrder() {
        Recommendation rec1 = Recommendation.builder()
                .id(UUID.randomUUID())
                .conceptTitle("First")
                .confidenceScore(0.8)
                .generatedAt(LocalDateTime.now().minusHours(2))
                .build();
        Recommendation rec2 = Recommendation.builder()
                .id(UUID.randomUUID())
                .conceptTitle("Second")
                .confidenceScore(0.9)
                .generatedAt(LocalDateTime.now())
                .build();

        when(recommendationRepo.findRecentByUserId(userId)).thenReturn(List.of(rec2, rec1));

        List<RecommendationResponse> result = service.getRecentRecommendations(userId);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getConceptTitle()).isEqualTo("Second");
        assertThat(result.get(1).getConceptTitle()).isEqualTo("First");
    }
}
