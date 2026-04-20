# BE-Activity 熟悉文档

## 1. 入口与职责
- Controller：`backend/src/main/java/com/example/qutongxing/controller/ActivityController.java`
- Service：`backend/src/main/java/com/example/qutongxing/service/impl/ActivityServiceImpl.java`

## 2. 活动生命周期（简）
1. 创建活动（可附图：文件/Base64/URL）。
2. 用户报名，记录状态为 `pending`。
3. 发起人审批：
   - 同意 -> `approved`
   - 拒绝 -> `rejected`
4. 已通过用户退出路径：
   - 提交退出申请 `quitRequested=true`
   - 发起人同意 -> 删除报名记录
   - 发起人拒绝 -> `quitRequested=false`
5. 活动删除限制：
   - 仅创建者可删
   - 若存在 `approved` 参与者则禁止删除

## 3. 关键接口与副作用
- `GET /activities`：支持 keyword + sortBy + sortOrder
- `POST /activities/{id}/join`：创建报名记录
- `POST /activities/{id}/quit`：仅 `pending/rejected` 可直接删记录
- `POST /activities/{id}/request-quit`：`approved` 用户发起退出
- 审批接口会改变报名记录状态或删除记录

## 4. 与前端强依赖字段
- 活动 DTO 输出：`joinStatus`、`pendingCount`、`quitRequestedCount`、`approvedCount`
- 图片输出：`imageBase64`

## 5. 风险点
- 大量 `RuntimeException` 文本作为业务错误，后续应统一错误码层。
- `searchAndSortActivities` 里先查后过滤，数据量增大时可能有性能压力。
