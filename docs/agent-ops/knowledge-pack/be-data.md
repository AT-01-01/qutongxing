# BE-Data 熟悉文档

## 1. 实体关系
- `User`（用户）
- `Activity`（活动）
- `ActivityParticipant`（用户-活动报名关系）

## 2. 关系说明
- `Activity.creator -> User`（多对一）
- `ActivityParticipant.user -> User`（多对一）
- `ActivityParticipant.activity -> Activity`（多对一）

## 3. 关键字段与状态
- `ActivityParticipant.status`：`pending` / `approved` / `rejected`
- `ActivityParticipant.quitRequested`：退出申请标志
- `Activity.contractAmount`：契约金
- `Activity.image`：二进制图片（BYTEA）

## 4. Repository 职责（摘要）
- `UserRepository`：用户唯一字段存在性、账号查找。
- `ActivityRepository`：活动列表、搜索、排序、按创建者查询。
- `ActivityParticipantRepository`：报名关系查询、状态计数、退出申请计数、存在性判断。

## 5. 数据一致性关注点
- 删除活动前需先删除报名记录，避免残留关系。
- 报名与审批流程依赖状态字段，严禁跨状态直接跳转。
- 计数字段由查询实时计算，避免脏缓存问题。
