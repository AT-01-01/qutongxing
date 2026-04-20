package com.example.qutongxing.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "qtx_activities")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Activity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "activity_date", nullable = false)
    private LocalDateTime activityDate;

    @Basic(fetch = FetchType.LAZY)
    @Column(columnDefinition = "BYTEA")
    private byte[] image;

    @Column(name = "contract_amount", nullable = false, precision = 10, scale = 2)
    private BigDecimal contractAmount;

    @Column(name = "refund_before_minutes", nullable = false)
    private Integer refundBeforeMinutes = 10;

    @Column(name = "refund_before_minutes_rate", nullable = false, precision = 4, scale = 2)
    private BigDecimal refundBeforeMinutesRate = new BigDecimal("0.50");

    @Column(name = "refund_before_hours", nullable = false)
    private Integer refundBeforeHours = 3;

    @Column(name = "refund_before_hours_rate", nullable = false, precision = 4, scale = 2)
    private BigDecimal refundBeforeHoursRate = new BigDecimal("0.80");

    @Column(name = "refund_before_early_rate", nullable = false, precision = 4, scale = 2)
    private BigDecimal refundBeforeEarlyRate = new BigDecimal("1.00");

    @Column(name = "late_arrival_window_hours", nullable = false)
    private Integer lateArrivalWindowHours = 2;

    @Column(name = "late_arrival_penalty_rate", nullable = false, precision = 4, scale = 2)
    private BigDecimal lateArrivalPenaltyRate = new BigDecimal("0.20");

    @Column(name = "checkin_distance_meters", nullable = false)
    private Integer checkinDistanceMeters = 120;

    @Column(name = "allow_member_direct_message", nullable = false)
    private Boolean allowMemberDirectMessage = true;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}