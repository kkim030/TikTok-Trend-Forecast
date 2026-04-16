package com.tiktoktrends.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder
public class CalendarEntryResponse {
    private UUID id;
    private String title;
    private String notes;
    private LocalDateTime scheduledAt;
    private String status;
    private UUID recommendationId;
}
