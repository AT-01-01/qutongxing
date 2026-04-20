package com.example.qutongxing.service;

import com.example.qutongxing.dto.*;
import com.example.qutongxing.entity.User;

public interface UserService {

    User register(UserRegisterDTO dto);

    LoginResponseDTO login(UserLoginDTO dto);

    LoginResponseDTO wechatLogin(WechatLoginDTO dto);

    LoginResponseDTO qqLogin(QQLoginDTO dto);

    LoginResponseDTO smsLogin(SmsLoginDTO dto);

    User findById(Long id);

    User findByUsername(String username);

    UserProfileDTO getProfile(Long userId);

    UserProfileDTO updateProfile(UpdateUserProfileDTO dto);
}