-- 在应用启动时兜底创建核心表，避免“数据库为空导致注册/登录直接失败”。
-- 这里使用最基础、最稳妥的 DDL 语句，避免复杂 PL/pgSQL 在初始化阶段解析失败。

CREATE TABLE IF NOT EXISTS qtx_users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255),
    phone VARCHAR(20) NOT NULL UNIQUE,
    avatar VARCHAR(255),
    wechat_id VARCHAR(100),
    qq_id VARCHAR(100),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS display_name VARCHAR(50);
ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS gender VARCHAR(10);
ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS real_name_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS bio VARCHAR(500);
ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE qtx_users ADD COLUMN IF NOT EXISTS address VARCHAR(255);

CREATE TABLE IF NOT EXISTS qtx_activities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    activity_date TIMESTAMP NOT NULL,
    image BYTEA,
    contract_amount NUMERIC(10, 2) NOT NULL,
    creator_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS refund_before_minutes INT NOT NULL DEFAULT 10;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS refund_before_minutes_rate NUMERIC(4,2) NOT NULL DEFAULT 0.50;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS refund_before_hours INT NOT NULL DEFAULT 3;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS refund_before_hours_rate NUMERIC(4,2) NOT NULL DEFAULT 0.80;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS refund_before_early_rate NUMERIC(4,2) NOT NULL DEFAULT 1.00;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS late_arrival_window_hours INT NOT NULL DEFAULT 2;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS late_arrival_penalty_rate NUMERIC(4,2) NOT NULL DEFAULT 0.20;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS checkin_distance_meters INT NOT NULL DEFAULT 120;
ALTER TABLE qtx_activities ADD COLUMN IF NOT EXISTS allow_member_direct_message BOOLEAN NOT NULL DEFAULT TRUE;

CREATE TABLE IF NOT EXISTS qtx_activity_participants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    activity_id BIGINT NOT NULL,
    attended BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    quit_requested BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP NOT NULL DEFAULT NOW()
);

ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMP;
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS last_latitude DOUBLE PRECISION;
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS last_longitude DOUBLE PRECISION;
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS last_location_at TIMESTAMP;
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS last_location_address VARCHAR(255);
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS paid_amount NUMERIC(10, 2);
ALTER TABLE qtx_activity_participants ADD COLUMN IF NOT EXISTS refunded_amount NUMERIC(10, 2) DEFAULT 0;

CREATE TABLE IF NOT EXISTS qtx_activity_chat_messages (
    id BIGSERIAL PRIMARY KEY,
    activity_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    content VARCHAR(2000) NOT NULL,
    message_type VARCHAR(20) NOT NULL DEFAULT 'text',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 外键关系交由 JPA 的 ddl-auto=update 维护，减少初始化脚本失败风险。

CREATE INDEX IF NOT EXISTS idx_qtx_activities_creator_id ON qtx_activities(creator_id);
CREATE INDEX IF NOT EXISTS idx_qtx_activity_participants_user_id ON qtx_activity_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_qtx_activity_participants_activity_id ON qtx_activity_participants(activity_id);
CREATE INDEX IF NOT EXISTS idx_qtx_activity_chat_messages_activity_id ON qtx_activity_chat_messages(activity_id);
CREATE INDEX IF NOT EXISTS idx_qtx_activity_chat_messages_activity_id_id ON qtx_activity_chat_messages(activity_id, id DESC);
