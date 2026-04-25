package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateUserProfileDTO {
    @NotNull(message = "userId不能为空")
    private Long userId;
    private String displayName;
    private String gender;
    private Boolean realNameVerified;
    private String bio;
    private String city;
    private String address;
    private String avatar;
}
