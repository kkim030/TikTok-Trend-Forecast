package com.rbcdirectinvesting.dto.response;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class PortfolioOverviewResponse {
    private BigDecimal totalValue;
    private BigDecimal totalCashBalance;
    private BigDecimal totalHoldingsValue;
    private BigDecimal totalGainLoss;
    private BigDecimal totalGainLossPercent;
    private BigDecimal dayChange;
    private BigDecimal dayChangePercent;
    private List<AccountSummaryResponse> accounts;
    private List<HoldingResponse> holdings;
}
