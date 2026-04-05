package com.rbcdirectinvesting.repository;

import com.rbcdirectinvesting.entity.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    Page<Transaction> findByAccountIdOrderBySettledAtDesc(UUID accountId, Pageable pageable);
    Page<Transaction> findByAccountUserIdOrderBySettledAtDesc(UUID userId, Pageable pageable);
}
