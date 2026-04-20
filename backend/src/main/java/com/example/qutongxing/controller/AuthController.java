package com.example.qutongxing.controller;

import com.example.qutongxing.dto.*;
import com.example.qutongxing.entity.User;
import com.example.qutongxing.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<User>> register(@Valid @RequestBody UserRegisterDTO dto) {
        User user = userService.register(dto);
        return ResponseEntity.ok(ApiResponse.success("注册成功", user));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDTO>> login(@Valid @RequestBody UserLoginDTO dto) {
        LoginResponseDTO response = userService.login(dto);
        return ResponseEntity.ok(ApiResponse.success("登录成功", response));
    }

    @PostMapping("/login/wechat")
    public ResponseEntity<ApiResponse<LoginResponseDTO>> wechatLogin(@Valid @RequestBody WechatLoginDTO dto) {
        LoginResponseDTO response = userService.wechatLogin(dto);
        return ResponseEntity.ok(ApiResponse.success("微信登录成功", response));
    }

    @PostMapping("/login/qq")
    public ResponseEntity<ApiResponse<LoginResponseDTO>> qqLogin(@Valid @RequestBody QQLoginDTO dto) {
        LoginResponseDTO response = userService.qqLogin(dto);
        return ResponseEntity.ok(ApiResponse.success("QQ登录成功", response));
    }

    @PostMapping("/login/sms")
    public ResponseEntity<ApiResponse<LoginResponseDTO>> smsLogin(@Valid @RequestBody SmsLoginDTO dto) {
        LoginResponseDTO response = userService.smsLogin(dto);
        return ResponseEntity.ok(ApiResponse.success("短信登录成功", response));
    }
}