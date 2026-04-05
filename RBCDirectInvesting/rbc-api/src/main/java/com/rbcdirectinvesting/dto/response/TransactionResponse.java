package com.rbcdirectinvesting.dto.response;

import com.rbcdirectinvesting.enums.TransactionType;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class TransactionResponse {
    private UUID id;
    private UUID accountId;
    private TransactionType type;
    private String symbol;
    private BigDecimal quantity;
    private BigDecimal price;
    private BigDecimal amount;
    private BigDecimal commission;
    private String description;
    private LocalDateTime settledAt;
}
