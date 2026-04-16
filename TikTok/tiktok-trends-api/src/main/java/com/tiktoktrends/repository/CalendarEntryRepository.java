package com.tiktoktrends.repository;

import com.tiktoktrends.entity.CalendarEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface CalendarEntryRepository extends JpaRepository<CalendarEntry, UUID> {

    List<CalendarEntry> findByUserIdAndScheduledAtBetweenOrderByScheduledAtAsc(
            UUID userId, LocalDateTime start, LocalDateTime end);
}
