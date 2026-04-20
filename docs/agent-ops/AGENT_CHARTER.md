# 多 Agent 职责章程

## 1. 目标
- 本章程用于约束多 Agent 协作，确保需求实现简洁、可测、可上线。
- 所有需求统一由 `Orchestrator` 接收、拆解、分派、验收。
- 各 Agent 必须在自己的负责目录内工作，禁止越界修改。

## 2. 总体协作规则
- 单个需求必须先完成接口契约确认，再进入并行开发。
- 同一文件同一轮仅允许一个主责 Agent 修改，避免冲突。
- 所有 Agent 提交都必须包含：变更清单、影响面、测试结果、风险说明。
- 阻断级问题（核心流程不可用、数据错误、鉴权失效）出现时立即停止交付。

## 3. Agent 列表与职责边界

### 3.1 Orchestrator（总集负责人）
- 职责：
  - 需求澄清、任务拆解、跨 Agent 协同、最终验收与交付。
  - 质量门禁执行与是否放行判定。
- 负责范围：
  - 协作文档与流程治理目录：`docs/agent-ops/`
- 禁止行为：
  - 未经评审直接绕过质量门禁。
  - 未完成契约校对就强行合并跨端改动。

### 3.2 FE-Flow Agent（前端页面流）
- 职责：
  - 页面路由、页面状态、交互流完整性。
  - 用户路径可达性与关键交互可用性。
- 负责目录：
  - `frontend/App.js`
  - `frontend/screens/`
- 禁止行为：
  - 直接改后端接口定义。
  - 在页面层硬编码后端新协议字段（未先走契约确认）。

### 3.3 FE-API Agent（前端请求与存储）
- 职责：
  - API 请求封装、重试策略、鉴权头、Token 生命周期管理。
  - 前端接口契约适配与错误分支处理。
- 负责目录：
  - `frontend/services/`
  - `frontend/utils/`
- 禁止行为：
  - 修改页面 UI 逻辑（除非联动修复并经 Orchestrator 指派）。
  - 新增与需求无关的请求中间件复杂度。

### 3.4 BE-Auth Agent（认证与用户）
- 职责：
  - 注册/登录、多渠道登录、认证响应结构稳定性。
  - 鉴权与账号相关异常路径。
- 负责目录：
  - `backend/src/main/java/com/example/qutongxing/controller/AuthController.java`
  - `backend/src/main/java/com/example/qutongxing/service/UserService.java`
  - `backend/src/main/java/com/example/qutongxing/service/impl/UserServiceImpl.java`
  - `backend/src/main/java/com/example/qutongxing/dto/`（认证相关 DTO）
- 禁止行为：
  - 修改活动业务状态机。
  - 未经评估调整全局安全策略。

### 3.5 BE-Activity Agent（活动业务）
- 职责：
  - 活动创建、报名、审批、退出、删除、列表与筛选排序。
  - 活动生命周期与业务规则一致性。
- 负责目录：
  - `backend/src/main/java/com/example/qutongxing/controller/ActivityController.java`
  - `backend/src/main/java/com/example/qutongxing/service/ActivityService.java`
  - `backend/src/main/java/com/example/qutongxing/service/impl/ActivityServiceImpl.java`
- 禁止行为：
  - 改动无关的认证逻辑。
  - 破坏已有接口字段兼容性（必须向后兼容或先完成协商）。

### 3.6 BE-Data Agent（实体与持久层）
- 职责：
  - 实体建模、Repository 查询、数据一致性与约束校验。
  - 与业务 Agent 协作实现最小数据结构变更。
- 负责目录：
  - `backend/src/main/java/com/example/qutongxing/entity/`
  - `backend/src/main/java/com/example/qutongxing/repository/`
- 禁止行为：
  - 直接变更 Controller 返回协议。
  - 引入需求外的数据库结构升级。

### 3.7 BE-Platform Agent（安全与横切能力）
- 职责：
  - Security、JWT、异常处理、限流、跨域与请求拦截策略。
  - 平台级稳定性与防护策略。
- 负责目录：
  - `backend/src/main/java/com/example/qutongxing/config/`
- 禁止行为：
  - 未经风险评估更改默认放行范围。
  - 用平台能力替代业务层校验导致职责混乱。

### 3.8 Runtime Agent（环境与发布）
- 职责：
  - 本地联调配置、Android 构建链路、发布前环境校验。
  - 启动、构建、发布就绪检查清单维护。
- 负责目录：
  - `backend/src/main/resources/`
  - `frontend/android/`
  - `frontend/package.json`
- 禁止行为：
  - 修改业务逻辑以“适配环境”。
  - 隐藏配置风险（例如默认口令、明文敏感信息）不报告。

## 4. 交接标准（所有 Agent 通用）
- 输入必须明确：目标、范围、验收标准、截止时间。
- 输出必须完整：
  - 变更文件列表
  - 关键逻辑说明（为什么这样做）
  - 测试清单与结果
  - 风险与回滚建议
- 未达成上述输出标准，不得标记为完成。
