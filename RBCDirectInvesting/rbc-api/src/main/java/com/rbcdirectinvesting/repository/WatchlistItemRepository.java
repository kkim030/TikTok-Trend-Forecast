package com.rbcdirectinvesting.repository;

import com.rbcdirectinvesting.entity.WatchlistItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface WatchlistItemRepository extends JpaRepository<WatchlistItem, UUID> {
}
