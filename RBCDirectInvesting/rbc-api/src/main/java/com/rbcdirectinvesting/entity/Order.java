package com.rbcdirectinvesting.entity;

import com.rbcdirectinvesting.enums.*;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "orders")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private Account account;

    @Column(nullable = false)
    private String symbol;

    @Column(nullable = false)
    private String exchange = "TSX";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderSide side;

    @Enumerated(EnumType.STRING)
    @Column(name = "order_type", nullable = false)
    private OrderType orderType;

    @Column(nullable = false, precision = 15, scale = 4)
    private BigDecimal quantity;

    @Column(name = "limit_price", precision = 15, scale = 4)
    private BigDecimal limitPrice;

    @Column(name = "stop_price", precision = 15, scale = 4)
    private BigDecimal stopPrice;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderDuration duration = OrderDuration.DAY;

    @Column(name = "gtd_date")
    private LocalDate gtdDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status = OrderStatus.PENDING;

    @Column(name = "filled_quantity", precision = 15, scale = 4)
    private BigDecimal filledQuantity = BigDecimal.ZERO;

    @Column(name = "filled_avg_price", precision = 15, scale = 4)
    private BigDecimal filledAvgPrice;

    @Column(name = "estimated_cost", precision = 15, scale = 2)
    private BigDecimal estimatedCost;

    @Column(precision = 10, scale = 2)
    private BigDecimal commission = new BigDecimal("9.95");

    @Column(name = "submitted_at", updatable = false)
    private LocalDateTime submittedAt = LocalDateTime.now();

    @Column(name = "filled_at")
    private LocalDateTime filledAt;

    @Column(name = "cancelled_at")
    private LocalDateTime cancelledAt;
}
