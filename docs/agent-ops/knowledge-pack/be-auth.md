# BE-Auth 熟悉文档

## 1. 入口与职责
- Controller：`backend/src/main/java/com/example/qutongxing/controller/AuthController.java`
- Service：`backend/src/main/java/com/example/qutongxing/service/impl/UserServiceImpl.java`

## 2. 登录方式矩阵
- 普通登录：用户名/手机号 + 密码
- 微信登录：`wechatId`（不存在则自动注册）
- QQ 登录：`qqId`（不存在则自动注册）
- 短信登录：手机号 + 验证码（当前固定校验 `123456`）

## 3. 核心行为
- 注册前校验：用户名、邮箱、手机号唯一。
- 密码使用 `BCryptPasswordEncoder` 加密。
- 登录成功统一返回 `LoginResponseDTO`，包含 JWT token 与用户信息。

## 4. 关键 DTO 契约（简）
- `UserRegisterDTO`：注册字段
- `UserLoginDTO`：用户名/手机号 + 密码
- `WechatLoginDTO` / `QQLoginDTO` / `SmsLoginDTO`
- `LoginResponseDTO`：`token`、`tokenType`、`userId`、`username`、`email`、`phone`
- 通用返回：`ApiResponse<T>`

## 5. 当前风险
- 短信验证码为固定值，仅适合开发阶段。
- 第三方登录自动注册生成默认邮箱/手机号，需后续补充合法性策略。
