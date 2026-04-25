package com.example.qutongxing.dto;

import lombok.Data;

@Data
public class UserProfileDTO {
    private Long userId;
    private String username;
    private String displayName;
    private String gender;
    private Boolean realNameVerified;
    private String bio;
    private String city;
    private String address;
    private String avatar;
    private String email;
    private String phone;
}
