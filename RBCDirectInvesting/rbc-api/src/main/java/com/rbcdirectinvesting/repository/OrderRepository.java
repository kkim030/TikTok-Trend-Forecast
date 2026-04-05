package com.rbcdirectinvesting.repository;

import com.rbcdirectinvesting.entity.Order;
import com.rbcdirectinvesting.enums.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface OrderRepository extends JpaRepository<Order, UUID> {
    Page<Order> findByAccountUserIdOrderBySubmittedAtDesc(UUID userId, Pageable pageable);
    List<Order> findByStatus(OrderStatus status);
    List<Order> findByAccountIdOrderBySubmittedAtDesc(UUID accountId);
}
