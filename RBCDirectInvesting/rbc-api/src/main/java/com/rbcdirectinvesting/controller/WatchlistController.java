package com.rbcdirectinvesting.controller;

import com.rbcdirectinvesting.dto.request.WatchlistItemRequest;
import com.rbcdirectinvesting.dto.request.WatchlistRequest;
import com.rbcdirectinvesting.dto.response.WatchlistResponse;
import com.rbcdirectinvesting.dto.response.WatchlistItemDto;
import com.rbcdirectinvesting.entity.Watchlist;
import com.rbcdirectinvesting.entity.WatchlistItem;
import com.rbcdirectinvesting.service.WatchlistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/watchlists")
@RequiredArgsConstructor
public class WatchlistController {

    private final WatchlistService watchlistService;

    @GetMapping
    public ResponseEntity<List<WatchlistResponse>> list(@AuthenticationPrincipal UserDetails user) {
        UUID userId = UUID.fromString(user.getUsername());
        List<WatchlistResponse> dtos = watchlistService.getUserWatchlists(userId).stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping
    public ResponseEntity<WatchlistResponse> create(@AuthenticationPrincipal UserDetails user,
                                            @Valid @RequestBody WatchlistRequest req) {
        UUID userId = UUID.fromString(user.getUsername());
        return ResponseEntity.ok(toDto(watchlistService.createWatchlist(userId, req.getName())));
    }

    @PutMapping("/{id}")
    public ResponseEntity<WatchlistResponse> rename(@PathVariable UUID id,
                                            @Valid @RequestBody WatchlistRequest req) {
        return ResponseEntity.ok(toDto(watchlistService.renameWatchlist(id, req.getName())));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        watchlistService.deleteWatchlist(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/items")
    public ResponseEntity<WatchlistItemDto> addItem(@PathVariable UUID id,
                                                  @Valid @RequestBody WatchlistItemRequest req) {
        WatchlistItem item = watchlistService.addItem(id, req.getSymbol(), req.getExchange());
        return ResponseEntity.ok(new WatchlistItemDto(item.getId(), item.getSymbol(), item.getExchange()));
    }

    @DeleteMapping("/{watchlistId}/items/{itemId}")
    public ResponseEntity<Void> removeItem(@PathVariable UUID watchlistId, @PathVariable UUID itemId) {
        watchlistService.removeItem(itemId);
        return ResponseEntity.noContent().build();
    }

    private WatchlistResponse toDto(Watchlist wl) {
        List<WatchlistItemDto> items = wl.getItems().stream()
                .map(i -> new WatchlistItemDto(i.getId(), i.getSymbol(), i.getExchange()))
                .toList();
        return new WatchlistResponse(wl.getId(), wl.getName(), items);
    }
}
