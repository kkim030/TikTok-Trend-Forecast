package com.rbcdirectinvesting.dto.response;

import com.rbcdirectinvesting.enums.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class OrderResponse {
    private UUID id;
    private UUID accountId;
    private String symbol;
    private String exchange;
    private OrderSide side;
    private OrderType orderType;
    private BigDecimal quantity;
    private BigDecimal limitPrice;
    private BigDecimal stopPrice;
    private OrderDuration duration;
    private OrderStatus status;
    private BigDecimal filledQuantity;
    private BigDecimal filledAvgPrice;
    private BigDecimal estimatedCost;
    private BigDecimal commission;
    private LocalDateTime submittedAt;
    private LocalDateTime filledAt;
}
