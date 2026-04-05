package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.dto.request.OrderRequest;
import com.rbcdirectinvesting.dto.response.OrderResponse;
import com.rbcdirectinvesting.dto.response.QuoteResponse;
import com.rbcdirectinvesting.entity.*;
import com.rbcdirectinvesting.enums.*;
import com.rbcdirectinvesting.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final AccountRepository accountRepository;
    private final HoldingRepository holdingRepository;
    private final TransactionRepository transactionRepository;
    private final QuoteService quoteService;

    @Transactional
    public OrderResponse submitOrder(OrderRequest req) {
        Account account = accountRepository.findById(req.getAccountId())
                .orElseThrow(() -> new RuntimeException("Account not found"));

        QuoteResponse quote = quoteService.getQuote(req.getSymbol());
        BigDecimal estimatedPrice = req.getOrderType() == OrderType.MARKET
                ? quote.getCurrentPrice()
                : req.getLimitPrice();

        BigDecimal commission = new BigDecimal("9.95");
        BigDecimal estimatedCost = estimatedPrice.multiply(req.getQuantity()).add(commission);

        Order order = Order.builder()
                .account(account)
                .symbol(req.getSymbol())
                .exchange(req.getExchange())
                .side(req.getSide())
                .orderType(req.getOrderType())
                .quantity(req.getQuantity())
                .limitPrice(req.getLimitPrice())
                .stopPrice(req.getStopPrice())
                .duration(req.getDuration())
                .gtdDate(req.getGtdDate())
                .status(OrderStatus.PENDING)
                .estimatedCost(estimatedCost)
                .commission(commission)
                .submittedAt(LocalDateTime.now())
                .build();

        order = orderRepository.save(order);

        // Market orders fill instantly
        if (req.getOrderType() == OrderType.MARKET) {
            fillOrder(order, quote.getCurrentPrice());
        }

        return toResponse(order);
    }

    @Transactional
    public OrderResponse cancelOrder(UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new RuntimeException("Cannot cancel order with status: " + order.getStatus());
        }
        order.setStatus(OrderStatus.CANCELLED);
        order.setCancelledAt(LocalDateTime.now());
        return toResponse(orderRepository.save(order));
    }

    public Page<OrderResponse> getUserOrders(UUID userId, Pageable pageable) {
        return orderRepository.findByAccountUserIdOrderBySubmittedAtDesc(userId, pageable)
                .map(this::toResponse);
    }

    public OrderResponse getOrder(UUID orderId) {
        return toResponse(orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found")));
    }

    // Simulate limit order fills every 5 seconds in demo mode
    @Scheduled(fixedDelay = 5000)
    @Transactional
    public void processLimitOrders() {
        List<Order> pending = orderRepository.findByStatus(OrderStatus.PENDING);
        for (Order order : pending) {
            if (order.getOrderType() == OrderType.LIMIT && order.getLimitPrice() != null) {
                QuoteResponse quote = quoteService.getQuote(order.getSymbol());
                boolean shouldFill = (order.getSide() == OrderSide.BUY && quote.getCurrentPrice().compareTo(order.getLimitPrice()) <= 0)
                        || (order.getSide() == OrderSide.SELL && quote.getCurrentPrice().compareTo(order.getLimitPrice()) >= 0);
                if (shouldFill) {
                    fillOrder(order, order.getLimitPrice());
                }
            }
        }
    }

    private void fillOrder(Order order, BigDecimal fillPrice) {
        order.setStatus(OrderStatus.FILLED);
        order.setFilledQuantity(order.getQuantity());
        order.setFilledAvgPrice(fillPrice);
        order.setFilledAt(LocalDateTime.now());
        orderRepository.save(order);

        Account account = order.getAccount();
        BigDecimal totalCost = fillPrice.multiply(order.getQuantity()).setScale(2, RoundingMode.HALF_UP);

        if (order.getSide() == OrderSide.BUY) {
            account.setCashBalance(account.getCashBalance().subtract(totalCost).subtract(order.getCommission()));
            upsertHolding(account, order, fillPrice);
        } else if (order.getSide() == OrderSide.SELL) {
            account.setCashBalance(account.getCashBalance().add(totalCost).subtract(order.getCommission()));
            reduceHolding(account, order);
        }
        accountRepository.save(account);

        Transaction tx = Transaction.builder()
                .account(account)
                .order(order)
                .type(order.getSide() == OrderSide.BUY ? TransactionType.BUY : TransactionType.SELL)
                .symbol(order.getSymbol())
                .quantity(order.getQuantity())
                .price(fillPrice)
                .amount(order.getSide() == OrderSide.BUY ? totalCost.negate() : totalCost)
                .commission(order.getCommission())
                .description(order.getSide() + " " + order.getQuantity() + " " + order.getSymbol() + " @ " + fillPrice)
                .settledAt(LocalDateTime.now())
                .build();
        transactionRepository.save(tx);
    }

    private void upsertHolding(Account account, Order order, BigDecimal price) {
        holdingRepository.findByAccountIdAndSymbolAndExchange(account.getId(), order.getSymbol(), order.getExchange())
                .ifPresentOrElse(
                        h -> {
                            BigDecimal totalCost = h.getAvgCost().multiply(h.getQuantity())
                                    .add(price.multiply(order.getQuantity()));
                            BigDecimal totalQty = h.getQuantity().add(order.getQuantity());
                            h.setAvgCost(totalCost.divide(totalQty, 4, RoundingMode.HALF_UP));
                            h.setQuantity(totalQty);
                            holdingRepository.save(h);
                        },
                        () -> holdingRepository.save(Holding.builder()
                                .account(account)
                                .symbol(order.getSymbol())
                                .exchange(order.getExchange())
                                .quantity(order.getQuantity())
                                .avgCost(price)
                                .currency(account.getCurrency())
                                .build())
                );
    }

    private void reduceHolding(Account account, Order order) {
        holdingRepository.findByAccountIdAndSymbolAndExchange(account.getId(), order.getSymbol(), order.getExchange())
                .ifPresent(h -> {
                    BigDecimal remaining = h.getQuantity().subtract(order.getQuantity());
                    if (remaining.compareTo(BigDecimal.ZERO) <= 0) {
                        holdingRepository.delete(h);
                    } else {
                        h.setQuantity(remaining);
                        holdingRepository.save(h);
                    }
                });
    }

    private OrderResponse toResponse(Order o) {
        return OrderResponse.builder()
                .id(o.getId())
                .accountId(o.getAccount().getId())
                .symbol(o.getSymbol())
                .exchange(o.getExchange())
                .side(o.getSide())
                .orderType(o.getOrderType())
                .quantity(o.getQuantity())
                .limitPrice(o.getLimitPrice())
                .stopPrice(o.getStopPrice())
                .duration(o.getDuration())
                .status(o.getStatus())
                .filledQuantity(o.getFilledQuantity())
                .filledAvgPrice(o.getFilledAvgPrice())
                .estimatedCost(o.getEstimatedCost())
                .commission(o.getCommission())
                .submittedAt(o.getSubmittedAt())
                .filledAt(o.getFilledAt())
                .build();
    }
}
