package com.example.qutongxing.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SendChatMessageDTO {
    @NotNull(message = "userId不能为空")
    private Long userId;

    @NotBlank(message = "消息内容不能为空")
    private String content;

    private String messageType = "text";
}
