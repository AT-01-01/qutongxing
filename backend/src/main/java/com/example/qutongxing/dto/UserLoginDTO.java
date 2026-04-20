package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserLoginDTO {

    @NotBlank(message = "登录账号不能为空")
    private String usernameOrPhone;

    @NotBlank(message = "密码不能为空")
    private String password;
}