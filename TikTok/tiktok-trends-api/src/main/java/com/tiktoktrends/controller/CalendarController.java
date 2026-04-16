package com.tiktoktrends.controller;

import com.tiktoktrends.dto.request.CalendarEntryRequest;
import com.tiktoktrends.dto.response.CalendarEntryResponse;
import com.tiktoktrends.dto.response.OptimalTimingResponse;
import com.tiktoktrends.entity.CalendarEntry;
import com.tiktoktrends.repository.CalendarEntryRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/calendar")
@RequiredArgsConstructor
public class CalendarController {

    private final CalendarEntryRepository calendarRepo;

    // ── GET /entries?month=2026-04 ──────────────────────────────────────
    @GetMapping("/entries")
    public List<CalendarEntryResponse> getEntries(
            @RequestParam String month,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        YearMonth ym = YearMonth.parse(month, DateTimeFormatter.ofPattern("yyyy-MM"));
        LocalDateTime start = ym.atDay(1).atStartOfDay();
        LocalDateTime end   = ym.atEndOfMonth().atTime(23, 59, 59);

        return calendarRepo
                .findByUserIdAndScheduledAtBetweenOrderByScheduledAtAsc(userId, start, end)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    // ── POST /entries ────────────────────────────────────────────────────
    @PostMapping("/entries")
    public CalendarEntryResponse createEntry(
            @Valid @RequestBody CalendarEntryRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        CalendarEntry entry = CalendarEntry.builder()
                .userId(userId)
                .title(req.getTitle())
                .notes(req.getNotes())
                .scheduledAt(req.getScheduledAt())
                .status(req.getStatus() != null ? req.getStatus() : "draft")
                .recommendationId(req.getRecommendationId())
                .build();
        return toResponse(calendarRepo.save(entry));
    }

    // ── PUT /entries/{id} ────────────────────────────────────────────────
    @PutMapping("/entries/{id}")
    public ResponseEntity<CalendarEntryResponse> updateEntry(
            @PathVariable UUID id,
            @Valid @RequestBody CalendarEntryRequest req,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        return calendarRepo.findById(id)
                .filter(e -> e.getUserId().equals(userId))
                .map(e -> {
                    if (req.getTitle()       != null) e.setTitle(req.getTitle());
                    if (req.getNotes()       != null) e.setNotes(req.getNotes());
                    if (req.getScheduledAt() != null) e.setScheduledAt(req.getScheduledAt());
                    if (req.getStatus()      != null) e.setStatus(req.getStatus());
                    return ResponseEntity.ok(toResponse(calendarRepo.save(e)));
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // ── DELETE /entries/{id} ─────────────────────────────────────────────
    @DeleteMapping("/entries/{id}")
    public ResponseEntity<Void> deleteEntry(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);
        return calendarRepo.findById(id)
                .filter(e -> e.getUserId().equals(userId))
                .<ResponseEntity<Void>>map(e -> {
                    calendarRepo.delete(e);
                    return ResponseEntity.noContent().build();
                })
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // ── GET /optimal-times ───────────────────────────────────────────────
    @GetMapping("/optimal-times")
    public OptimalTimingResponse getOptimalTimes(
            @AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = BaseController.extractUserId(userDetails);

        Map<String, double[]> heatmap = initHeatmap();
        List<CalendarEntry> postedEntries = calendarRepo
                .findByUserIdAndScheduledAtBetweenOrderByScheduledAtAsc(
                        userId,
                        LocalDateTime.now().minusMonths(6),
                        LocalDateTime.now())
                .stream()
                .filter(e -> "posted".equals(e.getStatus()))
                .collect(Collectors.toList());

        for (CalendarEntry e : postedEntries) {
            String day = e.getScheduledAt().getDayOfWeek().name();
            int hour = e.getScheduledAt().getHour();
            heatmap.computeIfAbsent(day, k -> new double[24])[hour] += 0.05;
        }

        // Apply general TikTok engagement curve (peak: eve 6–9 PM, lunch 12 PM)
        for (String day : heatmap.keySet()) {
            double[] hours = heatmap.get(day);
            hours[12] = Math.min(1.0, hours[12] + 0.25);
            hours[18] = Math.min(1.0, hours[18] + 0.40);
            hours[19] = Math.min(1.0, hours[19] + 0.35);
            hours[20] = Math.min(1.0, hours[20] + 0.30);
            if (day.equals("TUESDAY") || day.equals("THURSDAY")) {
                hours[18] = Math.min(1.0, hours[18] + 0.15);
            }
        }

        List<OptimalTimingResponse.TimeSlot> slots = new ArrayList<>();
        for (Map.Entry<String, double[]> entry : heatmap.entrySet()) {
            double[] hours = entry.getValue();
            for (int h = 0; h < 24; h++) {
                if (hours[h] > 0.1) {
                    slots.add(OptimalTimingResponse.TimeSlot.builder()
                            .dayOfWeek(entry.getKey())
                            .hour(h)
                            .predictedEngagement(hours[h])
                            .build());
                }
            }
        }
        slots.sort(Comparator.comparingDouble(OptimalTimingResponse.TimeSlot::getPredictedEngagement).reversed());

        Map<String, List<Double>> heatmapResponse = new LinkedHashMap<>();
        for (DayOfWeek dow : DayOfWeek.values()) {
            String key = dow.name();
            double[] arr = heatmap.getOrDefault(key, new double[24]);
            List<Double> vals = new ArrayList<>();
            for (double v : arr) vals.add(v);
            heatmapResponse.put(key, vals);
        }

        return OptimalTimingResponse.builder()
                .bestSlots(slots.stream().limit(5).collect(Collectors.toList()))
                .heatmap(heatmapResponse)
                .build();
    }

    // MARK: - Helpers

    private CalendarEntryResponse toResponse(CalendarEntry e) {
        return CalendarEntryResponse.builder()
                .id(e.getId())
                .title(e.getTitle())
                .notes(e.getNotes())
                .scheduledAt(e.getScheduledAt())
                .status(e.getStatus())
                .recommendationId(e.getRecommendationId())
                .build();
    }

    private Map<String, double[]> initHeatmap() {
        Map<String, double[]> map = new LinkedHashMap<>();
        for (DayOfWeek d : DayOfWeek.values()) map.put(d.name(), new double[24]);
        return map;
    }
}
