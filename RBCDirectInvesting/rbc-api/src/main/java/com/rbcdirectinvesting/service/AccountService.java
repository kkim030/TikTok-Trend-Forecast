package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.dto.response.AccountSummaryResponse;
import com.rbcdirectinvesting.dto.response.HoldingResponse;
import com.rbcdirectinvesting.entity.Account;
import com.rbcdirectinvesting.repository.AccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AccountService {

    private final AccountRepository accountRepository;
    private final HoldingService holdingService;

    public List<Account> getUserAccounts(UUID userId) {
        return accountRepository.findByUserId(userId);
    }

    public Account getAccount(UUID accountId) {
        return accountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));
    }

    public AccountSummaryResponse getAccountSummary(UUID accountId) {
        Account account = getAccount(accountId);
        List<HoldingResponse> holdings = holdingService.getAccountHoldings(accountId);

        BigDecimal holdingsValue = holdings.stream()
                .map(HoldingResponse::getMarketValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal bookValue = holdings.stream()
                .map(HoldingResponse::getBookValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalValue = account.getCashBalance().add(holdingsValue);
        BigDecimal totalGainLoss = holdingsValue.subtract(bookValue);
        BigDecimal gainLossPct = bookValue.compareTo(BigDecimal.ZERO) > 0
                ? totalGainLoss.divide(bookValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;

        return AccountSummaryResponse.builder()
                .id(account.getId())
                .accountNumber(account.getAccountNumber())
                .accountType(account.getAccountType())
                .currency(account.getCurrency())
                .cashBalance(account.getCashBalance())
                .holdingsValue(holdingsValue)
                .totalValue(totalValue)
                .totalGainLoss(totalGainLoss)
                .totalGainLossPercent(gainLossPct.setScale(2, RoundingMode.HALF_UP))
                .build();
    }
}
