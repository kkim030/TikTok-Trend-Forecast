package com.rbcdirectinvesting.dto.response;

import lombok.*;

import java.math.BigDecimal;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class QuoteResponse {
    private String symbol;
    private BigDecimal currentPrice;
    private BigDecimal change;
    private BigDecimal changePercent;
    private BigDecimal high;
    private BigDecimal low;
    private BigDecimal open;
    private BigDecimal previousClose;
    private Long volume;
    private Long timestamp;
}
