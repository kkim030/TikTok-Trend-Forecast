package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.dto.response.HoldingResponse;
import com.rbcdirectinvesting.dto.response.QuoteResponse;
import com.rbcdirectinvesting.entity.Holding;
import com.rbcdirectinvesting.repository.HoldingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HoldingService {

    private final HoldingRepository holdingRepository;
    private final QuoteService quoteService;

    public List<HoldingResponse> getAccountHoldings(UUID accountId) {
        return holdingRepository.findByAccountId(accountId).stream()
                .map(this::enrichWithQuote)
                .toList();
    }

    public List<HoldingResponse> getUserHoldings(UUID userId) {
        return holdingRepository.findByAccountUserId(userId).stream()
                .map(this::enrichWithQuote)
                .toList();
    }

    private HoldingResponse enrichWithQuote(Holding h) {
        QuoteResponse quote = quoteService.getQuote(h.getSymbol());
        BigDecimal bookValue = h.getQuantity().multiply(h.getAvgCost()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal marketValue = h.getQuantity().multiply(quote.getCurrentPrice()).setScale(2, RoundingMode.HALF_UP);
        BigDecimal gainLoss = marketValue.subtract(bookValue);
        BigDecimal gainLossPct = bookValue.compareTo(BigDecimal.ZERO) > 0
                ? gainLoss.divide(bookValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                : BigDecimal.ZERO;
        BigDecimal dayChange = h.getQuantity().multiply(quote.getChange()).setScale(2, RoundingMode.HALF_UP);

        return HoldingResponse.builder()
                .id(h.getId())
                .accountId(h.getAccount().getId())
                .symbol(h.getSymbol())
                .exchange(h.getExchange())
                .quantity(h.getQuantity())
                .avgCost(h.getAvgCost())
                .bookValue(bookValue)
                .currency(h.getCurrency())
                .currentPrice(quote.getCurrentPrice())
                .marketValue(marketValue)
                .gainLoss(gainLoss)
                .gainLossPercent(gainLossPct.setScale(2, RoundingMode.HALF_UP))
                .dayChange(dayChange)
                .dayChangePercent(quote.getChangePercent())
                .build();
    }
}
