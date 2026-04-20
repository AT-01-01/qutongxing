# Runtime 熟悉文档

## 1. 后端运行基线
- 框架：Spring Boot（Maven）
- 端口：`8086`
- 配置文件：`backend/src/main/resources/application.yml`
- 数据库：PostgreSQL（当前指向局域网地址）

## 2. 前端运行基线
- 框架：Expo + React Native
- 启动命令（位于 `frontend/`）：
  - `npm start`
  - `npm run android`
- Android 原生目录：`frontend/android/`

## 3. 联调关键点
- 前端 `BASE_URL` 与后端监听地址/端口必须匹配。
- 手机真机调试时，前端地址需可访问后端局域网 IP。
- 鉴权 token 存储在 SecureStore，切换环境需避免脏 token 影响。

## 4. 发布前检查（运行层）
- 前后端可正常启动，无阻断错误日志。
- Android 构建可完成，关键页面可交互。
- 数据库连接配置有效，连接池参数合理。
- 关键环境变量与敏感配置项已按环境隔离。
