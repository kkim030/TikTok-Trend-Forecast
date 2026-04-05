package com.rbcdirectinvesting.dto.response;

import com.rbcdirectinvesting.enums.AccountType;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AccountSummaryResponse {
    private UUID id;
    private String accountNumber;
    private AccountType accountType;
    private String currency;
    private BigDecimal cashBalance;
    private BigDecimal holdingsValue;
    private BigDecimal totalValue;
    private BigDecimal totalGainLoss;
    private BigDecimal totalGainLossPercent;
}
