package com.tiktoktrends.repository;

import com.tiktoktrends.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    Optional<User> findByTiktokHandle(String handle);
    Optional<User> findByTiktokOpenId(String tiktokOpenId);
    boolean existsByEmail(String email);
}
