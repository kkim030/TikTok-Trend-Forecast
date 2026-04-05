package com.rbcdirectinvesting.dto.response;

import java.util.UUID;

public record WatchlistItemDto(UUID id, String symbol, String exchange) {}
