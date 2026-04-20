package com.example.qutongxing.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ParticipantLocationDTO {
    private Long userId;
    private String username;
    private Double latitude;
    private Double longitude;
    private String address;
    private LocalDateTime updatedAt;
    private Boolean attended;
}
