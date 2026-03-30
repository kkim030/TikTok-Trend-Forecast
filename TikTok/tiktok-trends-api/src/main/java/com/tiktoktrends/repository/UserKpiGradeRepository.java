package com.tiktoktrends.repository;

import com.tiktoktrends.entity.UserKpiGrade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserKpiGradeRepository extends JpaRepository<UserKpiGrade, UUID> {
    Optional<UserKpiGrade> findBySnapshotId(UUID snapshotId);
}
