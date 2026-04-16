package com.tiktoktrends.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tiktoktrends.dto.response.RecommendationResponse;
import com.tiktoktrends.entity.Recommendation;
import com.tiktoktrends.entity.Trend;
import com.tiktoktrends.entity.User;
import com.tiktoktrends.repository.RecommendationRepository;
import com.tiktoktrends.repository.TrendRepository;
import com.tiktoktrends.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecommendationService {

    private final RecommendationRepository recommendationRepo;
    private final TrendRepository trendRepo;
    private final UserRepository userRepo;
    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${anthropic.api.key}")      private String anthropicApiKey;
    @Value("${anthropic.api.model}")    private String anthropicModel;
    @Value("${anthropic.api.base-url}") private String anthropicBaseUrl;

    /**
     * Generates a video recommendation for the authenticated user.
     * 1. Fetches top 5 active trends
     * 2. Builds a structured prompt with trend context + user niche
     * 3. Calls Claude API
     * 4. Parses the response and persists the recommendation
     */
    public RecommendationResponse generateRecommendation(UUID userId) {
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        List<Trend> topTrends = trendRepo.findTopActiveByType("hashtag", LocalDateTime.now(), 5);
        Trend topTrend = topTrends.isEmpty() ? null : topTrends.get(0);

        // Demo / no real key — short-circuit to a canned recommendation rather than 500.
        if (anthropicApiKey == null || anthropicApiKey.isBlank()
                || anthropicApiKey.equalsIgnoreCase("demo")
                || anthropicApiKey.startsWith("sk-ant-demo")) {
            return toDto(recommendationRepo.save(buildDemoRecommendation(user, topTrend)));
        }

        try {
            String prompt = buildPrompt(user, topTrends);
            String aiResponse = callClaudeApi(prompt);
            Recommendation saved = parseAndSave(aiResponse, user, topTrend);
            return toDto(saved);
        } catch (Exception e) {
            log.warn("Claude call failed ({}), falling back to canned recommendation", e.getMessage());
            return toDto(recommendationRepo.save(buildDemoRecommendation(user, topTrend)));
        }
    }

    private Recommendation buildDemoRecommendation(User user, Trend trend) {
        String trendKeyword = trend != null ? trend.getKeyword() : "fyp";
        String niche = user.getNiche() != null ? user.getNiche() : "lifestyle";
        return Recommendation.builder()
                .user(user)
                .trend(trend)
                .conceptTitle("POV: I tried the #" + trendKeyword + " trend in my " + niche + " niche")
                .conceptDescription("Open with a 1.5s hook (\"You won't believe this worked\"), "
                        + "then jump straight into the trend with a " + niche + "-specific twist. "
                        + "End on a slow-mo reveal and ask viewers what they'd do differently.")
                .suggestedMusic("Original Sound - viralbeats")
                .suggestedHashtags(List.of("#" + trendKeyword, "#fyp", "#" + niche, "#viral", "#trending"))
                .confidenceScore(0.88)
                .build();
    }

    public List<RecommendationResponse> getRecentRecommendations(UUID userId) {
        return recommendationRepo.findRecentByUserId(userId)
                .stream().map(this::toDto).collect(Collectors.toList());
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private String buildPrompt(User user, List<Trend> trends) {
        String trendSummary = trends.stream()
                .map(t -> String.format("- %s '%s' (velocity: %.2f, avg engagement: %.2f%%)",
                        t.getTrendType(), t.getKeyword(), t.getVelocityScore(), t.getEngagementAvg() * 100))
                .collect(Collectors.joining("\n"));

        return String.format("""
            You are an expert TikTok content strategist. A creator in the '%s' niche wants their next video idea.
            
            Current top trends on TikTok right now:
            %s
            
            Generate a specific, actionable video concept for this creator. Respond ONLY with a JSON object in this exact format:
            {
              "conceptTitle": "short catchy title under 10 words",
              "conceptDescription": "2-3 sentence description of exactly what to film and how",
              "suggestedMusic": "specific song or sound name that fits the trend",
              "suggestedHashtags": ["hashtag1", "hashtag2", "hashtag3", "hashtag4", "hashtag5"],
              "confidenceScore": 0.87
            }
            """, user.getNiche(), trendSummary);
    }

    private String callClaudeApi(String prompt) {
        Map<String, Object> requestBody = Map.of(
                "model", anthropicModel,
                "max_tokens", 1000,
                "messages", List.of(Map.of("role", "user", "content", prompt))
        );

        Map<?, ?> response = webClient.post()
                .uri(anthropicBaseUrl + "/messages")
                .header("x-api-key", anthropicApiKey)
                .header("anthropic-version", "2023-06-01")
                .header("content-type", "application/json")
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response == null) throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "No response from Claude API");

        List<?> content = (List<?>) response.get("content");
        Map<?, ?> firstBlock = (Map<?, ?>) content.get(0);
        return (String) firstBlock.get("text");
    }

    @SuppressWarnings("unchecked")
    private Recommendation parseAndSave(String json, User user, Trend trend) {
        try {
            // Strip any markdown fences Claude might include
            String cleaned = json.replaceAll("```json|```", "").trim();
            Map<String, Object> parsed = objectMapper.readValue(cleaned, Map.class);

            Recommendation rec = Recommendation.builder()
                    .user(user)
                    .trend(trend)
                    .conceptTitle((String) parsed.get("conceptTitle"))
                    .conceptDescription((String) parsed.get("conceptDescription"))
                    .suggestedMusic((String) parsed.get("suggestedMusic"))
                    .suggestedHashtags((List<String>) parsed.get("suggestedHashtags"))
                    .confidenceScore(((Number) parsed.get("confidenceScore")).doubleValue())
                    .build();

            return recommendationRepo.save(rec);
        } catch (Exception e) {
            log.error("Failed to parse Claude response: {}", json, e);
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Failed to parse AI recommendation", e);
        }
    }

    private RecommendationResponse toDto(Recommendation r) {
        return RecommendationResponse.builder()
                .id(r.getId())
                .conceptTitle(r.getConceptTitle())
                .conceptDescription(r.getConceptDescription())
                .suggestedMusic(r.getSuggestedMusic())
                .suggestedHashtags(r.getSuggestedHashtags())
                .confidenceScore(r.getConfidenceScore())
                .generatedAt(r.getGeneratedAt())
                .build();
    }
}
