package com.rbcdirectinvesting.controller;

import com.rbcdirectinvesting.dto.response.AccountSummaryResponse;
import com.rbcdirectinvesting.dto.response.HoldingResponse;
import com.rbcdirectinvesting.dto.response.PortfolioOverviewResponse;
import com.rbcdirectinvesting.entity.Account;
import com.rbcdirectinvesting.service.AccountService;
import com.rbcdirectinvesting.service.HoldingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;
    private final HoldingService holdingService;

    @GetMapping
    public ResponseEntity<List<AccountSummaryResponse>> listAccounts(@AuthenticationPrincipal UserDetails user) {
        UUID userId = UUID.fromString(user.getUsername());
        List<AccountSummaryResponse> summaries = accountService.getUserAccounts(userId).stream()
                .map(a -> accountService.getAccountSummary(a.getId()))
                .toList();
        return ResponseEntity.ok(summaries);
    }

    @GetMapping("/{id}/summary")
    public ResponseEntity<AccountSummaryResponse> accountSummary(@PathVariable UUID id) {
        return ResponseEntity.ok(accountService.getAccountSummary(id));
    }

    @GetMapping("/{id}/holdings")
    public ResponseEntity<List<HoldingResponse>> accountHoldings(@PathVariable UUID id) {
        return ResponseEntity.ok(holdingService.getAccountHoldings(id));
    }

    @GetMapping("/portfolio")
    public ResponseEntity<PortfolioOverviewResponse> portfolio(@AuthenticationPrincipal UserDetails user) {
        UUID userId = UUID.fromString(user.getUsername());
        List<AccountSummaryResponse> accounts = accountService.getUserAccounts(userId).stream()
                .map(a -> accountService.getAccountSummary(a.getId()))
                .toList();
        List<HoldingResponse> allHoldings = holdingService.getUserHoldings(userId);

        BigDecimal totalValue = accounts.stream().map(AccountSummaryResponse::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalCash = accounts.stream().map(AccountSummaryResponse::getCashBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalHoldings = accounts.stream().map(AccountSummaryResponse::getHoldingsValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalGL = accounts.stream().map(AccountSummaryResponse::getTotalGainLoss)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal dayChange = allHoldings.stream()
                .map(h -> h.getDayChange() != null ? h.getDayChange() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal bookValue = totalHoldings.subtract(totalGL);
        BigDecimal glPct = bookValue.compareTo(BigDecimal.ZERO) > 0
                ? totalGL.divide(bookValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;
        BigDecimal dayPct = totalHoldings.compareTo(BigDecimal.ZERO) > 0
                ? dayChange.divide(totalHoldings, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;

        return ResponseEntity.ok(PortfolioOverviewResponse.builder()
                .totalValue(totalValue)
                .totalCashBalance(totalCash)
                .totalHoldingsValue(totalHoldings)
                .totalGainLoss(totalGL)
                .totalGainLossPercent(glPct.setScale(2, RoundingMode.HALF_UP))
                .dayChange(dayChange)
                .dayChangePercent(dayPct.setScale(2, RoundingMode.HALF_UP))
                .accounts(accounts)
                .holdings(allHoldings)
                .build());
    }
}
