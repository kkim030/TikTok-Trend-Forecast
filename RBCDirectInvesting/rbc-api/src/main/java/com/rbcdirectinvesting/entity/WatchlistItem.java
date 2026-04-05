package com.rbcdirectinvesting.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "watchlist_items", uniqueConstraints = @UniqueConstraint(columnNames = {"watchlist_id", "symbol", "exchange"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class WatchlistItem {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "watchlist_id", nullable = false)
    private Watchlist watchlist;

    @Column(nullable = false)
    private String symbol;

    @Column(nullable = false)
    private String exchange = "TSX";

    @Column(name = "added_at", updatable = false)
    private LocalDateTime addedAt = LocalDateTime.now();
}
