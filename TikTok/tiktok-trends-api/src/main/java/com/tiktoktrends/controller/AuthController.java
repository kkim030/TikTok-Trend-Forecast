package com.tiktoktrends.controller;

import com.tiktoktrends.dto.request.LoginRequest;
import com.tiktoktrends.dto.request.RegisterRequest;
import com.tiktoktrends.dto.response.AuthResponse;
import com.tiktoktrends.entity.User;
import com.tiktoktrends.repository.UserRepository;
import com.tiktoktrends.security.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "http://localhost:3000")
public class AuthController {

    private final UserRepository userRepository;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        }

        User user = User.builder()
                .tiktokHandle(req.getTiktokHandle())
                .email(req.getEmail())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .niche(req.getNiche())
                .build();

        User saved = userRepository.save(user);
        String token = jwtUtil.generateToken(saved.getId().toString());

        log.info("New user registered: {}", saved.getTiktokHandle());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(AuthResponse.builder()
                        .token(token)
                        .userId(saved.getId())
                        .tiktokHandle(saved.getTiktokHandle())
                        .niche(saved.getNiche())
                        .build());
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest req) {
        User user = userRepository.findByEmail(req.getEmail())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }

        String token = jwtUtil.generateToken(user.getId().toString());

        return ResponseEntity.ok(AuthResponse.builder()
                .token(token)
                .userId(user.getId())
                .tiktokHandle(user.getTiktokHandle())
                .niche(user.getNiche())
                .build());
    }
}
