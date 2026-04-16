package com.tiktoktrends.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data @Builder
public class OptimalTimingResponse {
    private List<TimeSlot> bestSlots;
    private Map<String, List<Double>> heatmap; // "MONDAY": [0.02, 0.01, ...]

    @Data @Builder
    public static class TimeSlot {
        private String dayOfWeek;
        private int hour;
        private double predictedEngagement;
    }
}
