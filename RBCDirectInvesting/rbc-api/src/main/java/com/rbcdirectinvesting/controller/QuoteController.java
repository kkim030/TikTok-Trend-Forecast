package com.rbcdirectinvesting.controller;

import com.rbcdirectinvesting.dto.response.QuoteResponse;
import com.rbcdirectinvesting.service.QuoteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class QuoteController {

    private final QuoteService quoteService;

    @GetMapping("/quotes/{symbol}")
    public ResponseEntity<QuoteResponse> getQuote(@PathVariable String symbol) {
        return ResponseEntity.ok(quoteService.getQuote(symbol.toUpperCase()));
    }

    @GetMapping("/quotes/search")
    public ResponseEntity<List<Map<String, Object>>> searchSymbols(@RequestParam String q) {
        return ResponseEntity.ok(quoteService.searchSymbol(q));
    }

    @GetMapping("/market/overview")
    public ResponseEntity<List<QuoteResponse>> marketOverview() {
        return ResponseEntity.ok(quoteService.getMarketOverview());
    }
}
