package com.example.qutongxing.repository;

import com.example.qutongxing.entity.ActivityParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ActivityParticipantRepository extends JpaRepository<ActivityParticipant, Long> {

    List<ActivityParticipant> findByUserId(Long userId);

    List<ActivityParticipant> findByActivityId(Long activityId);

    List<ActivityParticipant> findByActivityIdAndStatus(Long activityId, String status);

    List<ActivityParticipant> findByActivityIdAndStatusAndUserIdNot(Long activityId, String status, Long userId);

    Optional<ActivityParticipant> findByUserIdAndActivityId(Long userId, Long activityId);

    Boolean existsByUserIdAndActivityId(Long userId, Long activityId);

    void deleteByActivityId(Long activityId);

    Long countByActivityIdAndStatus(Long activityId, String status);

    @Query("SELECT COUNT(p) FROM ActivityParticipant p WHERE p.activity.id = :activityId AND p.quitRequested = true")
    Long countByActivityIdAndQuitRequestedTrue(Long activityId);

    @Query("SELECT COUNT(p) FROM ActivityParticipant p WHERE p.activity.id = :activityId AND p.status = 'approved'")
    Long countByActivityIdAndStatusApproved(Long activityId);

    void deleteByUserIdAndActivityId(Long userId, Long activityId);

    @Query("SELECT p.activity.id FROM ActivityParticipant p WHERE p.user.id = :userId AND p.status = 'approved'")
    List<Long> findApprovedActivityIdsByUserId(@Param("userId") Long userId);
}
