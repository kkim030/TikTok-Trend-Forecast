package com.tiktoktrends.controller;

import com.tiktoktrends.dto.response.AuthResponse;
import com.tiktoktrends.entity.User;
import com.tiktoktrends.repository.UserRepository;
import com.tiktoktrends.security.JwtUtil;
import com.tiktoktrends.service.impl.TikTokOAuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
public class AuthController {

    private final TikTokOAuthService tikTokOAuthService;
    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;

    /**
     * Generates a TikTok OAuth authorization URL with a CSRF state token.
     * Frontend redirects the user to this URL to begin the OAuth flow.
     */
    @GetMapping("/tiktok/authorize")
    public ResponseEntity<Map<String, String>> getTikTokAuthUrl() {
        String authUrl = tikTokOAuthService.buildAuthorizationUrl();
        return ResponseEntity.ok(Map.of("authUrl", authUrl));
    }

    /**
     * Handles the TikTok OAuth callback.
     * Exchanges the authorization code for tokens, fetches user profile,
     * upserts the user, and returns a JWT.
     */
    @PostMapping("/tiktok/callback")
    public ResponseEntity<AuthResponse> handleTikTokCallback(@RequestBody Map<String, String> body) {
        String code  = body.get("code");
        String state = body.get("state");
        AuthResponse response = tikTokOAuthService.handleCallback(code, state);
        return ResponseEntity.ok(response);
    }

    /**
     * Demo login — returns a JWT for the seeded demo user.
     * Only works when demo data has been seeded (spring.profiles.active=demo).
     */
    @PostMapping("/demo")
    public ResponseEntity<AuthResponse> demoLogin() {
        User demoUser = userRepository.findByTiktokHandle("demo_creator")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Demo user not found. Start the server with spring.profiles.active=demo"));

        String jwt = jwtUtil.generateToken(demoUser.getId().toString());

        return ResponseEntity.ok(AuthResponse.builder()
                .token(jwt)
                .userId(demoUser.getId())
                .tiktokHandle(demoUser.getTiktokHandle())
                .displayName(demoUser.getDisplayName())
                .niche(demoUser.getNiche())
                .avatarUrl(demoUser.getAvatarUrl())
                .build());
    }
}
