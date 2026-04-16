package com.tiktoktrends.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
public class CalendarEntryRequest {
    @NotBlank
    private String title;
    private String notes;
    @NotNull
    private LocalDateTime scheduledAt;
    private String status = "draft";
    private UUID recommendationId;
}
