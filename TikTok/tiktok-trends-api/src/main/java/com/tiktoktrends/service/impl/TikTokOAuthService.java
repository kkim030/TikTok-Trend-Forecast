package com.tiktoktrends.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.tiktoktrends.dto.response.AuthResponse;
import com.tiktoktrends.entity.User;
import com.tiktoktrends.repository.UserRepository;
import com.tiktoktrends.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class TikTokOAuthService {

    private final UserRepository userRepo;
    private final JwtUtil jwtUtil;
    private final WebClient webClient;
    private final ObjectMapper objectMapper;
    private final StringRedisTemplate redisTemplate;

    @Value("${tiktok.api.client-key}")      private String clientKey;
    @Value("${tiktok.api.client-secret}")    private String clientSecret;
    @Value("${tiktok.api.base-url}")         private String tiktokApiBaseUrl;
    @Value("${tiktok.oauth.redirect-uri}")   private String redirectUri;

    private static final String OAUTH_STATE_PREFIX = "oauth_state:";

    /**
     * Builds the TikTok OAuth authorization URL and stores a CSRF state token in Redis.
     */
    public String buildAuthorizationUrl() {
        String state = UUID.randomUUID().toString();
        redisTemplate.opsForValue().set(OAUTH_STATE_PREFIX + state, "valid", 10, TimeUnit.MINUTES);

        return "https://www.tiktok.com/v2/auth/authorize/" +
                "?client_key=" + clientKey +
                "&response_type=code" +
                "&scope=user.info.basic,user.info.profile,user.info.stats,video.list" +
                "&redirect_uri=" + redirectUri +
                "&state=" + state;
    }

    /**
     * Handles the OAuth callback:
     * 1. Validates CSRF state
     * 2. Exchanges authorization code for access/refresh tokens
     * 3. Fetches user profile from TikTok
     * 4. Upserts user in database
     * 5. Returns JWT + user info
     */
    public AuthResponse handleCallback(String code, String state) {
        // 1. Validate CSRF state
        String stateKey = OAUTH_STATE_PREFIX + state;
        String stored = redisTemplate.opsForValue().get(stateKey);
        if (stored == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid or expired OAuth state");
        }
        redisTemplate.delete(stateKey);

        // 2. Exchange code for tokens
        Map<String, Object> tokenResponse = exchangeCodeForTokens(code);

        String accessToken  = (String) tokenResponse.get("access_token");
        String refreshToken = (String) tokenResponse.get("refresh_token");
        String openId       = (String) tokenResponse.get("open_id");
        int expiresIn       = ((Number) tokenResponse.get("expires_in")).intValue();

        // 3. Fetch user profile
        Map<String, Object> userInfo = fetchUserInfo(accessToken);

        String displayName = (String) userInfo.getOrDefault("display_name", "");
        String avatarUrl   = (String) userInfo.getOrDefault("avatar_url", "");
        String username    = (String) userInfo.getOrDefault("username", openId);

        // 4. Upsert user
        User user = userRepo.findByTiktokOpenId(openId)
                .map(existing -> {
                    existing.setTiktokAccessToken(accessToken);
                    existing.setTiktokRefreshToken(refreshToken);
                    existing.setTokenExpiresAt(LocalDateTime.now().plusSeconds(expiresIn));
                    existing.setDisplayName(displayName);
                    existing.setAvatarUrl(avatarUrl);
                    existing.setTiktokHandle(username);
                    return userRepo.save(existing);
                })
                .orElseGet(() -> {
                    User newUser = User.builder()
                            .tiktokOpenId(openId)
                            .tiktokHandle(username)
                            .displayName(displayName)
                            .avatarUrl(avatarUrl)
                            .tiktokAccessToken(accessToken)
                            .tiktokRefreshToken(refreshToken)
                            .tokenExpiresAt(LocalDateTime.now().plusSeconds(expiresIn))
                            .build();
                    return userRepo.save(newUser);
                });

        log.info("TikTok OAuth login successful for @{}", username);

        // 5. Generate JWT and return
        String jwt = jwtUtil.generateToken(user.getId().toString());
        return AuthResponse.builder()
                .token(jwt)
                .userId(user.getId())
                .tiktokHandle(user.getTiktokHandle())
                .niche(user.getNiche())
                .displayName(user.getDisplayName())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }

    /**
     * Refreshes a user's TikTok access token using their refresh token.
     */
    public void refreshTokenIfNeeded(User user) {
        if (user.getTokenExpiresAt() == null || user.getTiktokRefreshToken() == null) return;
        if (user.getTokenExpiresAt().isAfter(LocalDateTime.now().plusMinutes(30))) return;

        log.info("Refreshing TikTok token for @{}", user.getTiktokHandle());

        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("client_key", clientKey);
        formData.add("client_secret", clientSecret);
        formData.add("grant_type", "refresh_token");
        formData.add("refresh_token", user.getTiktokRefreshToken());

        @SuppressWarnings("unchecked")
        Map<String, Object> response = webClient.post()
                .uri("https://open.tiktokapis.com/v2/oauth/token/")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(BodyInserters.fromFormData(formData))
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response != null && response.containsKey("access_token")) {
            user.setTiktokAccessToken((String) response.get("access_token"));
            user.setTiktokRefreshToken((String) response.get("refresh_token"));
            int expiresIn = ((Number) response.get("expires_in")).intValue();
            user.setTokenExpiresAt(LocalDateTime.now().plusSeconds(expiresIn));
            userRepo.save(user);
            log.info("Token refreshed for @{}", user.getTiktokHandle());
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private Map<String, Object> exchangeCodeForTokens(String code) {
        MultiValueMap<String, String> formData = new LinkedMultiValueMap<>();
        formData.add("client_key", clientKey);
        formData.add("client_secret", clientSecret);
        formData.add("code", code);
        formData.add("grant_type", "authorization_code");
        formData.add("redirect_uri", redirectUri);

        Map<String, Object> response = webClient.post()
                .uri("https://open.tiktokapis.com/v2/oauth/token/")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(BodyInserters.fromFormData(formData))
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response == null || !response.containsKey("access_token")) {
            log.error("TikTok token exchange failed: {}", response);
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Failed to exchange TikTok authorization code");
        }

        return response;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> fetchUserInfo(String accessToken) {
        Map<String, Object> response = webClient.get()
                .uri(tiktokApiBaseUrl + "/user/info/?fields=open_id,display_name,avatar_url,username,follower_count,following_count,likes_count,video_count")
                .header("Authorization", "Bearer " + accessToken)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

        if (response == null || !response.containsKey("data")) {
            log.error("TikTok user info fetch failed: {}", response);
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Failed to fetch TikTok user info");
        }

        Map<String, Object> data = (Map<String, Object>) response.get("data");
        return (Map<String, Object>) data.get("user");
    }
}
