package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class ActivityCreateDTO {

    @NotBlank(message = "活动名称不能为空")
    private String name;

    private String description;

    @NotNull(message = "活动日期不能为空")
    private LocalDateTime activityDate;

    private byte[] image;

    @NotNull(message = "活动积分不能为空")
    private BigDecimal contractAmount;

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
