package com.example.qutongxing.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatMessageDTO {
    private Long id;
    private Long activityId;
    private Long senderId;
    private String senderName;
    private String content;
    private String messageType;
    private LocalDateTime createdAt;
}
