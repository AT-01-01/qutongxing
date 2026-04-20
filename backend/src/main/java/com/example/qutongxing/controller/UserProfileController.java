package com.example.qutongxing.controller;

import com.example.qutongxing.dto.ApiResponse;
import com.example.qutongxing.dto.UpdateUserProfileDTO;
import com.example.qutongxing.dto.UserProfileDTO;
import com.example.qutongxing.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserProfileController {

    @Autowired
    private UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileDTO>> getProfile(@RequestParam Long userId) {
        UserProfileDTO profile = userService.getProfile(userId);
        return ResponseEntity.ok(ApiResponse.success("获取个人信息成功", profile));
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileDTO>> updateProfile(@Valid @RequestBody UpdateUserProfileDTO dto) {
        UserProfileDTO profile = userService.updateProfile(dto);
        return ResponseEntity.ok(ApiResponse.success("更新个人信息成功", profile));
    }
}
