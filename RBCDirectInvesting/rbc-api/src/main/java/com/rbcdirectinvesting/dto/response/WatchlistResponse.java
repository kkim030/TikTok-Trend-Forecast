package com.rbcdirectinvesting.dto.response;

import java.util.List;
import java.util.UUID;

public record WatchlistResponse(UUID id, String name, List<WatchlistItemDto> items) {}
