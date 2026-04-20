# FE-Flow 熟悉文档

## 1. 页面地图
- 登录：`frontend/screens/LoginScreen.js`
- 注册：`frontend/screens/RegisterScreen.js`
- 活动列表：首页主入口 `frontend/screens/ActivityListScreen.js`
- 发布活动：`frontend/screens/CreateActivityScreen.js`
- 活动管理：`frontend/screens/ActivityManagementScreen.js`
- 个人中心：`frontend/screens/ProfileScreen.js`

## 2. 路由跳转矩阵
- 入口文件：`frontend/App.js`
- `Login -> Register`
- `Login -> ActivityList`
- `ActivityList -> CreateActivity`
- `ActivityList -> ActivityManagement`
- `ActivityList -> Profile`
- `ActivityManagement -> Back`

## 3. 关键交互路径
- 用户登录后进入活动列表，支持搜索与排序。
- 活动卡片支持报名、取消申请、申请退出（按 joinStatus 分支显示）。
- 管理页分“我创建的活动 / 我参加的活动”，支持报名审批与退出审批。

## 4. 当前边界与已知约束
- 主要状态在页面内管理（`useState`），未引入全局状态库。
- 大量交互通过 `Alert` 进行确认与反馈。
- 列表页与管理页都依赖活动接口字段：`joinStatus`、`pendingCount`、`quitRequestedCount`、`approvedCount`。

## 5. FE-Flow 回归重点
- 导航链路完整可达，不出现死路由或白屏。
- `joinStatus` 不同值时按钮分支正确。
- 搜索清空、排序弹窗、底部 Tab 切换行为一致。
