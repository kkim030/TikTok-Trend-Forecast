package com.rbcdirectinvesting.dto.request;

import com.rbcdirectinvesting.enums.OrderDuration;
import com.rbcdirectinvesting.enums.OrderSide;
import com.rbcdirectinvesting.enums.OrderType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class OrderRequest {
    @NotNull
    private UUID accountId;
    @NotBlank
    private String symbol;
    private String exchange = "TSX";
    @NotNull
    private OrderSide side;
    @NotNull
    private OrderType orderType;
    @NotNull @Positive
    private BigDecimal quantity;
    private BigDecimal limitPrice;
    private BigDecimal stopPrice;
    private OrderDuration duration = OrderDuration.DAY;
    private LocalDate gtdDate;
}
