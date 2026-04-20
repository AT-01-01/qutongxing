package com.example.qutongxing.dto;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class QuitPolicyPreviewDTO {
    private Long activityId;
    private Long userId;
    private String ruleMatched;
    private BigDecimal refundRate;
    private BigDecimal refundAmount;
    private BigDecimal penaltyAmount;
    private String message;
}
