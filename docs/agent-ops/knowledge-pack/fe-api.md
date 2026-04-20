# FE-API 熟悉文档

## 1. 基线
- 文件：`frontend/services/api.js`
- Base URL：`http://192.168.31.118:8086/api`
- 统一客户端：`axios.create({ timeout: 15000, retry: 3, retryDelay: 1000 })`

## 2. 鉴权时序
1. 请求拦截器优先从内存缓存 `cachedToken` 读取 token。
2. 缓存为空时，从 `expo-secure-store` 的 `qutongxing_token` 读取。
3. 有 token 时自动注入 `Authorization: Bearer <token>`。
4. 响应返回 `401` 时清理 token 与 user（内存 + SecureStore）。

## 3. 错误与重试边界
- 自动重试触发条件：
  - 超时（`ECONNABORTED` / timeout）
  - 网络错误（`Network Error`）
  - 服务端 `5xx`
- 限流 `429`：
  - 使用 `retry-after` 头部决定等待时间，默认 5000ms
- 超过重试上限直接失败抛出。

## 4. API 清单

### 4.1 认证
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/login/wechat`
- `POST /auth/login/qq`
- `POST /auth/login/sms`

### 4.2 活动
- `GET /activities`
- `GET /activities/{id}`
- `GET /activities/creator/{creatorId}`
- `GET /activities/participant/{userId}`
- `POST /activities`（`multipart/form-data`）
- `POST /activities/{id}/join`
- `POST /activities/{id}/quit`
- `POST /activities/{id}/request-quit`
- `POST /activities/{id}/approve-quit/{participantId}`
- `POST /activities/{id}/reject-quit/{participantId}`
- `DELETE /activities/{id}`
- `GET /activities/{id}/participants`
- `GET /activities/{id}/approved-participants`
- `POST /activities/{id}/approve/{participantId}`
- `POST /activities/{id}/reject/{participantId}`

## 5. 存储封装
- 文件：`frontend/utils/storage.js`
- Key：
  - token: `qutongxing_token`
  - user: `qutongxing_user`
- API：`getToken/setToken/removeToken/getUser/setUser/removeUser/clear`

## 6. FE-API 风险提示
- `retry` 不是 Axios 官方字段，属于自定义配置，必须保证调用方传入一致。
- Base URL 为局域网地址，跨环境需统一由 Runtime Agent 管控。
