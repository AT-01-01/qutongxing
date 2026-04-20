package com.example.qutongxing.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ParticipantRequestDTO {
    private Long id;
    private Long userId;
    private String username;
    private String email;
    private String phone;
    private Long activityId;
    private String activityName;
    private String status;
    private Boolean quitRequested;
    private String joinedAt;
}
