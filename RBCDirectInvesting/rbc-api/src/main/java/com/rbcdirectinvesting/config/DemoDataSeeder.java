package com.rbcdirectinvesting.config;

import com.rbcdirectinvesting.entity.*;
import com.rbcdirectinvesting.enums.*;
import com.rbcdirectinvesting.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Component
@Profile("demo")
@RequiredArgsConstructor
@Slf4j
public class DemoDataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final AccountRepository accountRepository;
    private final HoldingRepository holdingRepository;
    private final OrderRepository orderRepository;
    private final TransactionRepository transactionRepository;
    private final WatchlistRepository watchlistRepository;
    private final WatchlistItemRepository watchlistItemRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) return;
        log.info("Seeding demo data...");

        // Demo user
        User user = userRepository.save(User.builder()
                .email("demo@rbc.com")
                .passwordHash(passwordEncoder.encode("password123"))
                .fullName("Kelly")
                .createdAt(LocalDateTime.now().minusMonths(8))
                .build());

        // 3 accounts: TFSA, RRSP, Cash
        Account tfsa = accountRepository.save(Account.builder()
                .user(user).accountNumber("420-12345-1").accountType(AccountType.TFSA)
                .currency("CAD").cashBalance(new BigDecimal("12450.00")).createdAt(LocalDateTime.now().minusMonths(8)).build());

        Account rrsp = accountRepository.save(Account.builder()
                .user(user).accountNumber("420-12345-2").accountType(AccountType.RRSP)
                .currency("CAD").cashBalance(new BigDecimal("8320.50")).createdAt(LocalDateTime.now().minusMonths(6)).build());

        Account cash = accountRepository.save(Account.builder()
                .user(user).accountNumber("420-12345-3").accountType(AccountType.CASH)
                .currency("USD").cashBalance(new BigDecimal("25000.00")).createdAt(LocalDateTime.now().minusMonths(4)).build());

        // TFSA holdings — Canadian stocks
        seedHolding(tfsa, "RY", "TSX", 50, 138.50, "CAD");
        seedHolding(tfsa, "TD", "TSX", 75, 78.20, "CAD");
        seedHolding(tfsa, "ENB", "TSX", 120, 48.90, "CAD");
        seedHolding(tfsa, "CNR", "TSX", 30, 155.30, "CAD");
        seedHolding(tfsa, "SHOP", "TSX", 25, 92.40, "CAD");
        seedHolding(tfsa, "BCE", "TSX", 80, 50.20, "CAD");

        // RRSP holdings — mix
        seedHolding(rrsp, "BMO", "TSX", 40, 120.50, "CAD");
        seedHolding(rrsp, "BNS", "TSX", 60, 65.30, "CAD");
        seedHolding(rrsp, "CP", "TSX", 35, 100.80, "CAD");
        seedHolding(rrsp, "SU", "TSX", 90, 48.50, "CAD");
        seedHolding(rrsp, "T", "TSX", 100, 26.80, "CAD");

        // Cash account — US stocks
        seedHolding(cash, "AAPL", "NASDAQ", 20, 178.50, "USD");
        seedHolding(cash, "MSFT", "NASDAQ", 15, 380.20, "USD");
        seedHolding(cash, "NVDA", "NASDAQ", 10, 750.00, "USD");
        seedHolding(cash, "GOOGL", "NASDAQ", 25, 160.30, "USD");
        seedHolding(cash, "AMZN", "NASDAQ", 18, 170.40, "USD");

        // Seed transactions (last 6 months)
        seedTransactions(tfsa, rrsp, cash, user);

        // Seed orders
        seedOrders(tfsa, cash);

        // Watchlists
        seedWatchlists(user);

        log.info("Demo data seeded: 1 user, 3 accounts, {} holdings", holdingRepository.count());
    }

    private void seedHolding(Account acct, String sym, String exch, int qty, double avgCost, String curr) {
        holdingRepository.save(Holding.builder()
                .account(acct).symbol(sym).exchange(exch)
                .quantity(BigDecimal.valueOf(qty)).avgCost(BigDecimal.valueOf(avgCost))
                .currency(curr).build());
    }

    private void seedTransactions(Account tfsa, Account rrsp, Account cash, User user) {
        // Deposits
        seedTx(tfsa, null, TransactionType.DEPOSIT, null, null, null, 15000.00, "Initial TFSA contribution", 180);
        seedTx(rrsp, null, TransactionType.DEPOSIT, null, null, null, 10000.00, "RRSP contribution", 150);
        seedTx(cash, null, TransactionType.DEPOSIT, null, null, null, 30000.00, "Cash account funding", 120);

        // Buy transactions
        seedTx(tfsa, null, TransactionType.BUY, "RY", 50, 138.50, -6934.95, "BUY 50 RY @ 138.50", 170);
        seedTx(tfsa, null, TransactionType.BUY, "TD", 75, 78.20, -5874.95, "BUY 75 TD @ 78.20", 165);
        seedTx(tfsa, null, TransactionType.BUY, "ENB", 120, 48.90, -5877.95, "BUY 120 ENB @ 48.90", 140);
        seedTx(tfsa, null, TransactionType.BUY, "SHOP", 25, 92.40, -2319.95, "BUY 25 SHOP @ 92.40", 100);

        seedTx(rrsp, null, TransactionType.BUY, "BMO", 40, 120.50, -4829.95, "BUY 40 BMO @ 120.50", 140);
        seedTx(rrsp, null, TransactionType.BUY, "BNS", 60, 65.30, -3927.95, "BUY 60 BNS @ 65.30", 130);

        seedTx(cash, null, TransactionType.BUY, "AAPL", 20, 178.50, -3579.95, "BUY 20 AAPL @ 178.50", 110);
        seedTx(cash, null, TransactionType.BUY, "MSFT", 15, 380.20, -5712.95, "BUY 15 MSFT @ 380.20", 90);
        seedTx(cash, null, TransactionType.BUY, "NVDA", 10, 750.00, -7509.95, "BUY 10 NVDA @ 750.00", 60);

        // Dividends
        seedTx(tfsa, null, TransactionType.DIVIDEND, "RY", null, null, 68.00, "RY dividend Q1", 90);
        seedTx(tfsa, null, TransactionType.DIVIDEND, "TD", null, null, 73.50, "TD dividend Q1", 88);
        seedTx(tfsa, null, TransactionType.DIVIDEND, "ENB", null, null, 106.80, "ENB dividend Q1", 85);
        seedTx(rrsp, null, TransactionType.DIVIDEND, "BMO", null, null, 56.00, "BMO dividend Q1", 87);
    }

    private void seedTx(Account acct, Order order, TransactionType type, String symbol,
                         Integer qty, Double price, double amount, String desc, int daysAgo) {
        transactionRepository.save(Transaction.builder()
                .account(acct).order(order).type(type).symbol(symbol)
                .quantity(qty != null ? BigDecimal.valueOf(qty) : null)
                .price(price != null ? BigDecimal.valueOf(price) : null)
                .amount(BigDecimal.valueOf(amount))
                .commission(type == TransactionType.BUY || type == TransactionType.SELL ? new BigDecimal("9.95") : BigDecimal.ZERO)
                .description(desc)
                .settledAt(LocalDateTime.now().minusDays(daysAgo))
                .build());
    }

    private void seedOrders(Account tfsa, Account cash) {
        // A pending limit order
        orderRepository.save(Order.builder()
                .account(tfsa).symbol("RY").exchange("TSX").side(OrderSide.BUY)
                .orderType(OrderType.LIMIT).quantity(BigDecimal.valueOf(25))
                .limitPrice(BigDecimal.valueOf(140.00)).duration(OrderDuration.GTC)
                .status(OrderStatus.PENDING).commission(new BigDecimal("9.95"))
                .submittedAt(LocalDateTime.now().minusHours(2)).build());

        // A filled market order
        orderRepository.save(Order.builder()
                .account(cash).symbol("TSLA").exchange("NASDAQ").side(OrderSide.BUY)
                .orderType(OrderType.MARKET).quantity(BigDecimal.valueOf(5))
                .duration(OrderDuration.DAY).status(OrderStatus.FILLED)
                .filledQuantity(BigDecimal.valueOf(5)).filledAvgPrice(BigDecimal.valueOf(245.30))
                .estimatedCost(BigDecimal.valueOf(1236.45)).commission(new BigDecimal("9.95"))
                .submittedAt(LocalDateTime.now().minusDays(3)).filledAt(LocalDateTime.now().minusDays(3)).build());

        // A cancelled order
        orderRepository.save(Order.builder()
                .account(tfsa).symbol("SHOP").exchange("TSX").side(OrderSide.SELL)
                .orderType(OrderType.LIMIT).quantity(BigDecimal.valueOf(10))
                .limitPrice(BigDecimal.valueOf(115.00)).duration(OrderDuration.DAY)
                .status(OrderStatus.CANCELLED).commission(new BigDecimal("9.95"))
                .submittedAt(LocalDateTime.now().minusDays(5)).cancelledAt(LocalDateTime.now().minusDays(5)).build());
    }

    private void seedWatchlists(User user) {
        Watchlist techWl = watchlistRepository.save(Watchlist.builder()
                .user(user).name("Tech Stocks").createdAt(LocalDateTime.now().minusMonths(3)).build());
        for (String sym : List.of("AAPL", "MSFT", "GOOGL", "NVDA", "TSLA", "META", "SHOP")) {
            String exch = sym.equals("SHOP") ? "TSX" : "NASDAQ";
            watchlistItemRepository.save(WatchlistItem.builder()
                    .watchlist(techWl).symbol(sym).exchange(exch).addedAt(LocalDateTime.now().minusDays(60)).build());
        }

        Watchlist bankWl = watchlistRepository.save(Watchlist.builder()
                .user(user).name("Canadian Banks").createdAt(LocalDateTime.now().minusMonths(2)).build());
        for (String sym : List.of("RY", "TD", "BMO", "BNS", "CM")) {
            watchlistItemRepository.save(WatchlistItem.builder()
                    .watchlist(bankWl).symbol(sym).exchange("TSX").addedAt(LocalDateTime.now().minusDays(40)).build());
        }
    }
}
