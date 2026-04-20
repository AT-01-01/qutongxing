package com.example.qutongxing.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatConversationDTO {
    private Long activityId;
    private String activityName;
    private Long lastMessageId;
    private String lastMessageContent;
    private LocalDateTime lastMessageTime;
    private Long lastSenderId;
    private String lastSenderName;
}
