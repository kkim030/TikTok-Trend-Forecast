package com.rbcdirectinvesting.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class WatchlistItemRequest {
    @NotBlank
    private String symbol;
    private String exchange = "TSX";
}
