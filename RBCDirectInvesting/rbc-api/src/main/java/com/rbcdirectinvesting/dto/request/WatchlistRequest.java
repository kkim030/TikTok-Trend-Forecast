package com.rbcdirectinvesting.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class WatchlistRequest {
    @NotBlank
    private String name;
}
