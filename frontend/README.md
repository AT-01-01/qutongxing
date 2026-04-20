# 趣同行 Flutter 前端

当前目录已由 React Native 迁移为 Flutter 工程，旧工程备份在同级目录 `frontend_legacy`。

## 快速启动

```bash
cd frontend
flutter pub get
flutter run
```

## 指定平台运行

```bash
# Windows 桌面
flutter run -d windows

# Edge Web
flutter run -d edge
```

如果运行 Windows 时报 `symlink support`，请先开启开发者模式：

```bash
start ms-settings:developers
```

## 联调配置

- 后端地址在 `lib/services/api_service.dart`：
  - 默认：`http://localhost:8086/api`
- 如果后端地址变化，请同步修改 `_baseUrl`。
- Android 真机联调时，手机与后端必须处于同一网络可达。

## 已迁移页面

- 登录：`/login`
- 注册：`/register`
- 活动列表：`/activities`
- 创建活动：`/create`
- 活动管理：`/manage`
- 个人中心：`/profile`

## 质量校验

```bash
flutter analyze
flutter test
```

两项通过后再进入联调验收。
