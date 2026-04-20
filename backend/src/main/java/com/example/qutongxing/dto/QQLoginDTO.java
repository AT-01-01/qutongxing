package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class QQLoginDTO {

    @NotBlank(message = "QQ号不能为空")
    private String qqId;

    private String username;
    private String phone;
}