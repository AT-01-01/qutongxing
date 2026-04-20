package com.example.qutongxing.dto;

import lombok.Data;

@Data
public class LoginResponseDTO {

    private String token;
    private String tokenType = "Bearer";
    private Long userId;
    private String username;
    private String email;
    private String phone;
}