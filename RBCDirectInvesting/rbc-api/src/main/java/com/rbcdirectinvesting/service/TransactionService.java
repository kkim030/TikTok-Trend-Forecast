package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.dto.response.TransactionResponse;
import com.rbcdirectinvesting.entity.Transaction;
import com.rbcdirectinvesting.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;

    public Page<TransactionResponse> getAccountTransactions(UUID accountId, Pageable pageable) {
        return transactionRepository.findByAccountIdOrderBySettledAtDesc(accountId, pageable)
                .map(this::toResponse);
    }

    public Page<TransactionResponse> getUserTransactions(UUID userId, Pageable pageable) {
        return transactionRepository.findByAccountUserIdOrderBySettledAtDesc(userId, pageable)
                .map(this::toResponse);
    }

    private TransactionResponse toResponse(Transaction t) {
        return TransactionResponse.builder()
                .id(t.getId())
                .accountId(t.getAccount().getId())
                .type(t.getType())
                .symbol(t.getSymbol())
                .quantity(t.getQuantity())
                .price(t.getPrice())
                .amount(t.getAmount())
                .commission(t.getCommission())
                .description(t.getDescription())
                .settledAt(t.getSettledAt())
                .build();
    }
}
