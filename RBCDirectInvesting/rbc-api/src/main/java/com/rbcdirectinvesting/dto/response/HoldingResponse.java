package com.rbcdirectinvesting.dto.response;

import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class HoldingResponse {
    private UUID id;
    private UUID accountId;
    private String symbol;
    private String exchange;
    private BigDecimal quantity;
    private BigDecimal avgCost;
    private BigDecimal bookValue;
    private String currency;
    // Enriched with live quote data
    private BigDecimal currentPrice;
    private BigDecimal marketValue;
    private BigDecimal gainLoss;
    private BigDecimal gainLossPercent;
    private BigDecimal dayChange;
    private BigDecimal dayChangePercent;
}
