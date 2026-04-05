package com.rbcdirectinvesting.service;

import com.rbcdirectinvesting.entity.*;
import com.rbcdirectinvesting.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WatchlistService {

    private final WatchlistRepository watchlistRepository;
    private final WatchlistItemRepository watchlistItemRepository;
    private final UserRepository userRepository;

    public List<Watchlist> getUserWatchlists(UUID userId) {
        return watchlistRepository.findByUserId(userId);
    }

    @Transactional
    public Watchlist createWatchlist(UUID userId, String name) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return watchlistRepository.save(Watchlist.builder()
                .user(user).name(name).createdAt(LocalDateTime.now()).build());
    }

    @Transactional
    public Watchlist renameWatchlist(UUID watchlistId, String name) {
        Watchlist wl = watchlistRepository.findById(watchlistId)
                .orElseThrow(() -> new RuntimeException("Watchlist not found"));
        wl.setName(name);
        return watchlistRepository.save(wl);
    }

    @Transactional
    public void deleteWatchlist(UUID watchlistId) {
        watchlistRepository.deleteById(watchlistId);
    }

    @Transactional
    public WatchlistItem addItem(UUID watchlistId, String symbol, String exchange) {
        Watchlist wl = watchlistRepository.findById(watchlistId)
                .orElseThrow(() -> new RuntimeException("Watchlist not found"));
        WatchlistItem item = WatchlistItem.builder()
                .watchlist(wl).symbol(symbol).exchange(exchange).addedAt(LocalDateTime.now()).build();
        return watchlistItemRepository.save(item);
    }

    @Transactional
    public void removeItem(UUID itemId) {
        watchlistItemRepository.deleteById(itemId);
    }
}
