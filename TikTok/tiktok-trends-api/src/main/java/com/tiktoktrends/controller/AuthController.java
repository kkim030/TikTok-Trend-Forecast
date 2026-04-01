package com.tiktoktrends.controller;

import com.tiktoktrends.dto.response.AuthResponse;
import com.tiktoktrends.service.impl.TikTokOAuthService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
public class AuthController {

    private final TikTokOAuthService tikTokOAuthService;

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
}
