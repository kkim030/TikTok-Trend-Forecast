package com.rbcdirectinvesting.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "holdings", uniqueConstraints = @UniqueConstraint(columnNames = {"account_id", "symbol", "exchange"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Holding {

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

    @Column(nullable = false, precision = 15, scale = 4)
    private BigDecimal quantity;

    @Column(name = "avg_cost", nullable = false, precision = 15, scale = 4)
    private BigDecimal avgCost;

    @Column(nullable = false)
    private String currency = "CAD";
}
