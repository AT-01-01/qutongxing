package com.example.qutongxing.repository;

import com.example.qutongxing.entity.Activity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActivityRepository extends JpaRepository<Activity, Long> {

    List<Activity> findByCreatorId(Long creatorId);

    List<Activity> findAllByOrderByCreatedAtDesc();

    List<Activity> findAllByOrderByContractAmountDesc();

    List<Activity> findAllByOrderByContractAmountAsc();

    List<Activity> findAllByOrderByActivityDateDesc();

    List<Activity> findAllByOrderByActivityDateAsc();

    @Query("SELECT a FROM Activity a ORDER BY (SELECT COUNT(p) FROM ActivityParticipant p WHERE p.activity.id = a.id AND p.status = 'approved') DESC")
    List<Activity> findAllByOrderByParticipantCountDesc();

    @Query("SELECT a FROM Activity a WHERE LOWER(a.name) LIKE LOWER(CONCAT('%', :keyword, '%')) OR LOWER(a.description) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    List<Activity> searchByKeyword(@Param("keyword") String keyword);
}