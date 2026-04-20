# 趣同行前端依赖包清单

## 项目信息

- **项目名称**: qutongxing (趣同行)
- **Expo SDK**: 54.0.0
- **React Native**: 0.81.5

## 依赖包列表

### 生产依赖 (dependencies)

| 包名 | 版本 | 说明 |
|------|------|------|
| expo | ~54.0.0 | Expo框架核心 |
| expo-secure-store | ^55.0.13 | 安全存储（替代localStorage） |
| expo-status-bar | ~3.0.9 | 状态栏管理 |
| react | ^19.1.0 | React核心库 |
| react-dom | ^19.1.0 | React DOM渲染 |
| react-native | ^0.81.5 | React Native核心 |
| react-native-gesture-handler | ^2.31.1 | 手势处理 |
| react-native-safe-area-context | ~5.6.0 | 安全区域处理 |
| react-native-screens | ~4.16.0 | 原生屏幕导航 |
| react-native-web | ^0.21.2 | React Native Web支持 |
| @react-navigation/native | ^6.1.18 | 导航核心 |
| @react-navigation/stack | ^6.3.29 | 堆栈导航 |
| axios | ^1.6.8 | HTTP客户端 |
| @react-native-community/datetimepicker | ^7.6.2 | 日期时间选择器 |
| react-native-image-picker | ^7.1.0 | 图片选择（拍照/相册/链接） |

### 开发依赖 (devDependencies)

| 包名 | 版本 | 说明 |
|------|------|------|
| @babel/core | ^7.24.0 | Babel核心 |
| babel-preset-expo | ~54.0.10 | Expo Babel预设 |

## 安装命令

```bash
npm install
```

## 手动安装特定依赖

```bash
# 核心依赖
npm install expo@~54.0.0 expo-secure-store@^55.0.13 expo-status-bar@~3.0.9

# React相关
npm install react@^19.1.0 react-dom@^19.1.0 react-native@^0.81.5 react-native-web@^0.21.2

# React Navigation
npm install @react-navigation/native@^6.1.18 @react-navigation/stack@^6.3.29

# React Native相关
npm install react-native-gesture-handler@^2.31.1 react-native-safe-area-context@~5.6.0 react-native-screens@~4.16.0

# 其他
npm install axios@^1.6.8 @react-native-community/datetimepicker@^7.6.2 react-native-image-picker@^7.1.0

# 开发依赖
npm install --save-dev @babel/core@^7.24.0 babel-preset-expo@~54.0.10
```

## 注意事项

1. **存储方案**: 使用 `expo-secure-store` 替代 `localStorage`，因为React Native不支持浏览器的localStorage API

2. **导航方案**: 使用 `@react-navigation/stack` 而非 `@react-navigation/native-stack`，因为native-stack在React Native 0.81上有兼容性问题

3. **日期选择**: 使用 `@react-native-community/datetimepicker@7.6.2`，这是与Expo SDK 54兼容的版本

4. **安装参数**: 所有依赖安装时建议添加 `--legacy-peer-deps` 参数，避免版本冲突

   ```bash
   npm install <package-name> --legacy-peer-deps
   ```

5. **启动命令**:

   ```bash
   # 开发服务器
   npx expo start --port 8102

   # 清除缓存重新启动
   npx expo start -c --port 8102
   ```
