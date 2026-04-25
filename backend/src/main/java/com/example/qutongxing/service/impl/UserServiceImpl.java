package com.example.qutongxing.service.impl;

import com.example.qutongxing.config.JwtTokenUtil;
import com.example.qutongxing.dto.*;
import com.example.qutongxing.entity.User;
import com.example.qutongxing.repository.UserRepository;
import com.example.qutongxing.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenUtil jwtTokenUtil;

    @Override
    public User register(UserRegisterDTO dto) {
        if (userRepository.existsByUsername(dto.getUsername())) {
            throw new RuntimeException("用户名已存在");
        }
        if (userRepository.existsByEmail(dto.getEmail())) {
            throw new RuntimeException("邮箱已存在");
        }
        if (userRepository.existsByPhone(dto.getPhone())) {
            throw new RuntimeException("手机号已存在");
        }

        User user = new User();
        user.setUsername(dto.getUsername());
        user.setEmail(dto.getEmail());
        user.setPassword(passwordEncoder.encode(dto.getPassword()));
        user.setPhone(dto.getPhone());
        user.setWechatId(dto.getWechatId());
        user.setQqId(dto.getQqId());

        return userRepository.save(user);
    }

    @Override
    public LoginResponseDTO login(UserLoginDTO dto) {
        User user = userRepository.findByUsernameOrPhone(dto.getUsernameOrPhone(), dto.getUsernameOrPhone())
                .orElseThrow(() -> new RuntimeException("用户不存在，请先注册"));

        if (!passwordEncoder.matches(dto.getPassword(), user.getPassword())) {
            throw new RuntimeException("用户名或密码错误");
        }

        return buildLoginResponse(user);
    }

    @Override
    public LoginResponseDTO wechatLogin(WechatLoginDTO dto) {
        User user = userRepository.findByWechatId(dto.getWechatId())
                .orElseGet(() -> createUserFromWechat(dto));

        return buildLoginResponse(user);
    }

    @Override
    public LoginResponseDTO qqLogin(QQLoginDTO dto) {
        User user = userRepository.findByQqId(dto.getQqId())
                .orElseGet(() -> createUserFromQQ(dto));

        return buildLoginResponse(user);
    }

    @Override
    public LoginResponseDTO smsLogin(SmsLoginDTO dto) {
        User user = userRepository.findByPhone(dto.getPhone())
                .orElseThrow(() -> new RuntimeException("用户不存在"));

        if (!validateSmsCode(dto.getPhone(), dto.getCode())) {
            throw new RuntimeException("验证码错误");
        }

        return buildLoginResponse(user);
    }

    @Override
    public User findById(Long id) {
        return userRepository.findById(id).orElse(null);
    }

    @Override
    public User findByUsername(String username) {
        return userRepository.findByUsername(username).orElse(null);
    }

    @Override
    public UserProfileDTO getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        return toProfile(user);
    }

    @Override
    public UserProfileDTO updateProfile(UpdateUserProfileDTO dto) {
        User user = userRepository.findById(dto.getUserId())
                .orElseThrow(() -> new RuntimeException("用户不存在"));
        if (dto.getDisplayName() != null) {
            user.setDisplayName(dto.getDisplayName().trim());
        }
        if (dto.getGender() != null && !Boolean.TRUE.equals(user.getRealNameVerified())) {
            user.setGender(dto.getGender().trim());
        }
        if (dto.getRealNameVerified() != null) {
            user.setRealNameVerified(dto.getRealNameVerified());
        }
        if (dto.getBio() != null) {
            user.setBio(dto.getBio().trim());
        }
        if (dto.getCity() != null) {
            user.setCity(dto.getCity().trim());
        }
        if (dto.getAddress() != null) {
            user.setAddress(dto.getAddress().trim());
        }
        if (dto.getAvatar() != null) {
            user.setAvatar(dto.getAvatar().trim());
        }
        userRepository.save(user);
        return toProfile(user);
    }

    private User createUserFromWechat(WechatLoginDTO dto) {
        User user = new User();
        user.setUsername(dto.getUsername() != null ? dto.getUsername() : "wx_" + dto.getWechatId());
        user.setEmail("wx_" + dto.getWechatId() + "@example.com");
        user.setPhone(dto.getPhone() != null ? dto.getPhone() : "WX_" + dto.getWechatId());
        user.setWechatId(dto.getWechatId());
        user.setPassword(passwordEncoder.encode("wechat_" + dto.getWechatId()));
        return userRepository.save(user);
    }

    private User createUserFromQQ(QQLoginDTO dto) {
        User user = new User();
        user.setUsername(dto.getUsername() != null ? dto.getUsername() : "qq_" + dto.getQqId());
        user.setEmail("qq_" + dto.getQqId() + "@example.com");
        user.setPhone(dto.getPhone() != null ? dto.getPhone() : "QQ_" + dto.getQqId());
        user.setQqId(dto.getQqId());
        user.setPassword(passwordEncoder.encode("qq_" + dto.getQqId()));
        return userRepository.save(user);
    }

    private boolean validateSmsCode(String phone, String code) {
        return code.equals("123456");
    }

    private LoginResponseDTO buildLoginResponse(User user) {
        LoginResponseDTO response = new LoginResponseDTO();
        response.setToken(jwtTokenUtil.generateToken(user.getId(), user.getUsername()));
        response.setTokenType("Bearer");
        response.setUserId(user.getId());
        response.setUsername(user.getUsername());
        response.setEmail(user.getEmail());
        response.setPhone(user.getPhone());
        return response;
    }

    private UserProfileDTO toProfile(User user) {
        UserProfileDTO dto = new UserProfileDTO();
        dto.setUserId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setDisplayName(user.getDisplayName());
        dto.setGender(user.getGender());
        dto.setRealNameVerified(Boolean.TRUE.equals(user.getRealNameVerified()));
        dto.setBio(user.getBio());
        dto.setCity(user.getCity());
        dto.setAddress(user.getAddress());
        dto.setAvatar(user.getAvatar());
        dto.setEmail(user.getEmail());
        dto.setPhone(user.getPhone());
        return dto;
    }
}
