package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class WechatLoginDTO {

    @NotBlank(message = "微信ID不能为空")
    private String wechatId;

    private String username;
    private String phone;
}