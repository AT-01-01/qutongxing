# BE-Platform 熟悉文档

## 1. 平台能力范围
- 目录：`backend/src/main/java/com/example/qutongxing/config/`
- 关键组件：
  - `SecurityConfig`
  - `JwtTokenUtil`
  - `GlobalExceptionHandler`
  - `RateLimitInterceptor`
  - `WebMvcConfig`

## 2. 当前安全策略
- `SecurityFilterChain` 为无状态会话（STATLESS）。
- CORS 开启并允许所有来源模式（`*`）。
- 当前请求放行：`/api/auth/**` 与 `/api/activities/**`。

## 3. 影响面
- 认证控制：JWT 生成与校验逻辑影响所有鉴权接口。
- 错误输出：全局异常处理影响前端错误展示与重试策略判断。
- 限流：429 分支会触发前端等待后重试逻辑。

## 4. 风险点
- 过宽的 CORS 放行策略仅适合开发阶段。
- 活动接口当前放行，生产前需按业务需要收敛鉴权边界。
- 限流规则应与前端重试机制同步校验，防止放大流量。
