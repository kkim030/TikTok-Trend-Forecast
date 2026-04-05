package com.rbcdirectinvesting.repository;

import com.rbcdirectinvesting.entity.Holding;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface HoldingRepository extends JpaRepository<Holding, UUID> {
    List<Holding> findByAccountId(UUID accountId);
    List<Holding> findByAccountUserId(UUID userId);
    Optional<Holding> findByAccountIdAndSymbolAndExchange(UUID accountId, String symbol, String exchange);
}
