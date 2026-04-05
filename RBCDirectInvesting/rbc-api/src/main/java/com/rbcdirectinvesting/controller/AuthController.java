package com.rbcdirectinvesting.controller;

import com.rbcdirectinvesting.dto.request.LoginRequest;
import com.rbcdirectinvesting.dto.request.RegisterRequest;
import com.rbcdirectinvesting.dto.response.AuthResponse;
import com.rbcdirectinvesting.entity.User;
import com.rbcdirectinvesting.repository.UserRepository;
import com.rbcdirectinvesting.security.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
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
                .email(req.getEmail())
                .passwordHash(passwordEncoder.encode(req.getPassword()))
                .fullName(req.getFullName())
                .createdAt(LocalDateTime.now())
                .build();
        user = userRepository.save(user);
        String token = jwtUtil.generateToken(user.getId().toString());
        return ResponseEntity.ok(AuthResponse.builder()
                .token(token).userId(user.getId())
                .email(user.getEmail()).fullName(user.getFullName()).build());
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
                .token(token).userId(user.getId())
                .email(user.getEmail()).fullName(user.getFullName()).build());
    }

    @PostMapping("/demo")
    public ResponseEntity<AuthResponse> demoLogin() {
        User user = userRepository.findByEmail("demo@rbc.com")
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Demo user not found. Start with spring.profiles.active=demo"));
        String token = jwtUtil.generateToken(user.getId().toString());
        return ResponseEntity.ok(AuthResponse.builder()
                .token(token).userId(user.getId())
                .email(user.getEmail()).fullName(user.getFullName()).build());
    }
}
