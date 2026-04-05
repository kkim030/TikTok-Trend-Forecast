package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.dto.response.QuoteResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Service
@Slf4j
public class QuoteService {

    private final WebClient webClient;
    private final String apiKey;

    // Simulated base prices for demo mode
    private static final Map<String, Double> SIMULATED_PRICES = Map.ofEntries(
            Map.entry("RY", 145.20), Map.entry("TD", 82.50), Map.entry("BMO", 127.80),
            Map.entry("BNS", 68.90), Map.entry("CM", 65.40), Map.entry("ENB", 52.30),
            Map.entry("CNR", 165.50), Map.entry("CP", 108.20), Map.entry("SHOP", 105.60),
            Map.entry("BCE", 46.80), Map.entry("T", 28.50), Map.entry("SU", 55.70),
            Map.entry("AAPL", 195.20), Map.entry("MSFT", 420.50), Map.entry("GOOGL", 175.80),
            Map.entry("AMZN", 185.60), Map.entry("NVDA", 880.50), Map.entry("TSLA", 245.30),
            Map.entry("META", 505.20), Map.entry("JPM", 198.70),
            // Indices
            Map.entry("^GSPTSE", 22450.00), Map.entry("^GSPC", 5280.00),
            Map.entry("^DJI", 39850.00), Map.entry("^IXIC", 16750.00)
    );

    private final Random random = new Random();

    public QuoteService(WebClient webClient, @Value("${finnhub.api.key:}") String apiKey) {
        this.webClient = webClient;
        this.apiKey = apiKey;
    }

    public QuoteResponse getQuote(String symbol) {
        if (apiKey != null && !apiKey.isBlank()) {
            return fetchFromFinnhub(symbol);
        }
        return simulateQuote(symbol);
    }

    public List<QuoteResponse> getMarketOverview() {
        return List.of(
                getQuote("^GSPTSE"),
                getQuote("^GSPC"),
                getQuote("^DJI"),
                getQuote("^IXIC")
        );
    }

    public List<Map<String, Object>> searchSymbol(String query) {
        // Simple demo search from known symbols
        List<Map<String, Object>> results = new ArrayList<>();
        for (String sym : SIMULATED_PRICES.keySet()) {
            if (sym.toLowerCase().contains(query.toLowerCase()) && !sym.startsWith("^")) {
                results.add(Map.of("symbol", sym, "description", getCompanyName(sym), "type", "Common Stock"));
            }
        }
        return results;
    }

    private QuoteResponse simulateQuote(String symbol) {
        double basePrice = SIMULATED_PRICES.getOrDefault(symbol, 50.0 + random.nextDouble() * 150);
        double drift = (random.nextDouble() - 0.48) * basePrice * 0.03;
        double current = basePrice + drift;
        double prevClose = basePrice;
        double change = current - prevClose;
        double changePct = (change / prevClose) * 100;

        return QuoteResponse.builder()
                .symbol(symbol)
                .currentPrice(bd(current))
                .change(bd(change))
                .changePercent(bd(changePct))
                .high(bd(current * 1.012))
                .low(bd(current * 0.988))
                .open(bd(prevClose + (random.nextDouble() - 0.5) * 2))
                .previousClose(bd(prevClose))
                .volume((long) (random.nextDouble() * 5_000_000 + 500_000))
                .timestamp(System.currentTimeMillis() / 1000)
                .build();
    }

    private QuoteResponse fetchFromFinnhub(String symbol) {
        try {
            Map<?, ?> resp = webClient.get()
                    .uri("https://finnhub.io/api/v1/quote?symbol={sym}&token={key}", symbol, apiKey)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (resp == null) return simulateQuote(symbol);

            return QuoteResponse.builder()
                    .symbol(symbol)
                    .currentPrice(toBd(resp.get("c")))
                    .change(toBd(resp.get("d")))
                    .changePercent(toBd(resp.get("dp")))
                    .high(toBd(resp.get("h")))
                    .low(toBd(resp.get("l")))
                    .open(toBd(resp.get("o")))
                    .previousClose(toBd(resp.get("pc")))
                    .timestamp(resp.get("t") != null ? ((Number) resp.get("t")).longValue() : System.currentTimeMillis() / 1000)
                    .build();
        } catch (Exception e) {
            log.warn("Finnhub API error for {}: {}", symbol, e.getMessage());
            return simulateQuote(symbol);
        }
    }

    private BigDecimal bd(double val) {
        return BigDecimal.valueOf(val).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal toBd(Object val) {
        if (val == null) return BigDecimal.ZERO;
        return BigDecimal.valueOf(((Number) val).doubleValue()).setScale(2, RoundingMode.HALF_UP);
    }

    private String getCompanyName(String symbol) {
        return switch (symbol) {
            case "RY" -> "Royal Bank of Canada";
            case "TD" -> "Toronto-Dominion Bank";
            case "BMO" -> "Bank of Montreal";
            case "BNS" -> "Bank of Nova Scotia";
            case "CM" -> "CIBC";
            case "ENB" -> "Enbridge Inc.";
            case "CNR" -> "Canadian National Railway";
            case "CP" -> "Canadian Pacific Kansas City";
            case "SHOP" -> "Shopify Inc.";
            case "BCE" -> "BCE Inc.";
            case "T" -> "TELUS Corp.";
            case "SU" -> "Suncor Energy";
            case "AAPL" -> "Apple Inc.";
            case "MSFT" -> "Microsoft Corp.";
            case "GOOGL" -> "Alphabet Inc.";
            case "AMZN" -> "Amazon.com Inc.";
            case "NVDA" -> "NVIDIA Corp.";
            case "TSLA" -> "Tesla Inc.";
            case "META" -> "Meta Platforms Inc.";
            case "JPM" -> "JPMorgan Chase & Co.";
            default -> symbol;
        };
    }
}
