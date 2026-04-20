package com.example.qutongxing.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ActivityResponseDTO {

    private Long id;
    private String name;
    private String description;
    private LocalDateTime activityDate;
    private String imageBase64;
    private BigDecimal contractAmount;
    private Long creatorId;
    private String creatorName;
    private LocalDateTime createdAt;
    private String joinStatus;
    private Integer pendingCount;
    private Integer quitRequestedCount;
    private Integer approvedCount;
    private Integer refundBeforeMinutes;
    private BigDecimal refundBeforeMinutesRate;
    private Integer refundBeforeHours;
    private BigDecimal refundBeforeHoursRate;
    private BigDecimal refundBeforeEarlyRate;
    private Integer lateArrivalWindowHours;
    private BigDecimal lateArrivalPenaltyRate;
    private Integer checkinDistanceMeters;
    private Boolean allowMemberDirectMessage;
}
